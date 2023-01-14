
const submitButton = document.getElementById("submit");

window.onload = (e) => {
    fetch("http://158.160.52.254:80/comments", { mode: "cors", headers: { 'AllowCrossOrigin': "*" }, "method": "GET" }).then(async response => {
        const result = await response.json();
        const replicaVersion = document.createElement("div");
        const name = document.createElement("div");
        replicaVersion.innerHTML = response.headers.get("backend-version");
        name.innerHTML = response.headers.get("backend-name");
        replicaVersion.id = "backendVersion";
        name.id = "backendName";
        document.body.appendChild(replicaVersion);
        document.body.appendChild(name);
        result.forEach(element => {
            const newComment = document.createElement("div");
            newComment.innerHTML = element.text;
            newComment.classList.add("comment");
            document.getElementById("wrapperComments").appendChild(newComment);
        });
    })
    fetch("/", { "method": "HEAD" }).then((response) => {
        const frontVersion = document.createElement("div");
        frontVersion.innerHTML = response.headers.get("X-AMZ-Meta-Version");
        frontVersion.id = "frontVersion"
        document.body.appendChild(frontVersion);
    })
};

submitButton.addEventListener("click", (e) => {
    e.preventDefault();

    const newCommentText = document.getElementById("textarea").value;

    fetch("http://158.160.52.254:80/comments", {
        mode: "cors", headers: { 'AllowCrossOrigin': "*" }, "method": "POST",
        "body": JSON.stringify({ text: newCommentText, created: Date.now() })
    }).then(_ => {
        const newComment = document.createElement("div");
        newComment.innerHTML = newCommentText;
        newComment.classList.add("comment");
        document.getElementById("wrapperComments").insertAdjacentElement("afterBegin", newComment);
    })
})
