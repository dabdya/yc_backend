from aiohttp import web
import aiohttp_cors, os

import argparse, ydb, ydb.iam 
from functools import partial
from datetime import datetime
from pathlib import Path


routes = web.RouteTableDef()

def load_environment(file: Path) -> None:
    import dotenv
    dotenv.load_dotenv(file)

def execute_query(session, query):
    return session.transaction().execute(
        query,
        commit_tx=True,
        settings= ydb.BaseRequestSettings().with_timeout(3).with_operation_timeout(2),
    )


def add_version(get_response):
    async def get_response_with_version(*args, **kwargs):
        response = await get_response(*args, **kwargs)
        version = os.environ.get("VERSION", 0)
        name = os.environ.get("NAME", "unknown")
        response.headers["Backend-Version"] = version
        response.headers["Backend-Name"] = name
        return response
    return get_response_with_version


@routes.get("/ping")
@add_version
async def ping(request: web.Request) -> web.Response:
    return web.Response(text="pong")
    

@routes.get("/comments")
@add_version
async def get_comments(request: web.Request) -> web.Response:
    db = request.config_dict.get("db", None)
    
    select_query = \
    """
    SELECT `comment_id`, `created`, `text`
    FROM `comments`
    ORDER BY `created` DESC;
    """

    result = await db.retry_operation(execute_query, select_query)
    response = [
        {
            k: v if not isinstance(v, bytes) else v.decode() 
            for k, v in row.items()
        } 
        for row in result[0].rows
    ]

    json_response = web.json_response(response)
    return json_response


@routes.post("/comments")
@add_version
async def create_comment(request: web.Request) -> web.Response:
    db = request.config_dict.get("db", None)

    try:
        ts = (await request.json())["created"]
        created = datetime.utcfromtimestamp(ts).strftime('%Y-%m-%dT%H:%M:%S.%fZ')
    except Exception as err:
        err = "Invalid timestamp"
        return web.Response(status=400, text=err)

    import random
    upsert_query = \
    """
    UPSERT INTO `comments`
    (`comment_id`, `created`, `text`)
    VALUES ({}, Timestamp(\"{}\"), \"{}\");
    """.format(random.randint(0, 1000000000), created, (await request.json())["text"])

    result = await db.retry_operation(execute_query, upsert_query)
    return web.json_response({"message": "OK"})


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-e", "--endpoint", type=str, required = True, 
        help = "Defines connection string for cluster"
    )

    parser.add_argument(
        "-d", "--database", type=str, required = True, 
        help = "Defines where the queried database is located in cluster"
    )
    parser.add_argument(
        "-c", "--credentials", type=str, required = True, 
        help = "Service account credentials"
    )

    return parser.parse_args()


async def setup_database(app: web.Application, args):

    driver = ydb.aio.Driver(
        endpoint = args.endpoint,
        database = args.database,
        credentials = ydb.iam.ServiceAccountCredentials.from_file(args.credentials)
    )

    await driver.wait(timeout = 5, fail_fast = True)
    db = ydb.aio.SessionPool(driver, size = 10)
    app["db"] = db
    yield
    await db.stop()
    await driver.stop()


if __name__ == "__main__":
    load_environment("environment.env")

    app = web.Application()
    app.add_routes(routes)
    app.cleanup_ctx.append(
        partial(setup_database, args = parse_args())
    )

    cors = aiohttp_cors.setup(app, defaults={
    "*": aiohttp_cors.ResourceOptions(
            allow_credentials=True,
            expose_headers="*",
            allow_headers="*"
        )
    })

    for route in list(app.router.routes()):
        cors.add(route)

    web.run_app(app)
    