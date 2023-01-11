from uuid import UUID

class Comment:
    __slots__ = ("comment_id", "text")

    def __init__(self, comment_id: UUID, text: str):
        self.comment_id = comment_id
        self.text = text