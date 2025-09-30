def status_ok(code: int) -> bool:
    # Be flexible (your create endpoint may return 200 or 201)
    return code in (200, 201)


def test_health(test_client):
    r = test_client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_create_and_read_task(test_client):
    # Create
    r = test_client.post("/tasks/", json={"title": "Test task"})
    assert status_ok(r.status_code), r.text
    body = r.json()
    assert body["title"] == "Test task"
    assert body["completed"] is False
    assert body["id"] > 0

    # Get by id
    tid = body["id"]
    r2 = test_client.get(f"/tasks/{tid}")
    assert r2.status_code == 200
    assert r2.json()["id"] == tid


def test_list_filters(test_client):
    # seed
    for title, tag, completed in [
        ("buy milk", "home", False),
        ("file taxes", "admin", False),
        ("finish PR", "work", True),
    ]:
        r = test_client.post("/tasks/", json={"title": title, "tag": tag})
        assert status_ok(r.status_code)

    # list all
    r = test_client.get("/tasks/")
    assert r.status_code == 200
    items = r.json()
    assert len(items) >= 3

    # filter by tag
    r = test_client.get("/tasks/?tag=work")
    assert r.status_code == 200
    items = r.json()
    assert all(i["tag"] == "work" for i in items)

    # filter by completed
    r = test_client.get("/tasks/?completed=true")
    assert r.status_code == 200
    items = r.json()
    assert all(i["completed"] is True for i in items)

    # search (title contains)
    r = test_client.get("/tasks/?search=milk")
    assert r.status_code == 200
    items = r.json()
    assert any("milk" in i["title"].lower() for i in items)


def test_get_not_found(test_client):
    r = test_client.get("/tasks/999999")
    assert r.status_code == 404
    assert r.json()["detail"].lower().startswith("task not found")


def test_update_task(test_client):
    # create
    r = test_client.post("/tasks/", json={"title": "initial", "tag": "t"})
    assert status_ok(r.status_code)
    tid = r.json()["id"]

    # update
    r2 = test_client.put(
        f"/tasks/{tid}", json={"title": "updated", "tag": "x", "description": None}
    )
    assert r2.status_code == 200
    assert r2.json()["title"] == "updated"
    assert r2.json()["tag"] == "x"


def test_complete_task(test_client):
    r = test_client.post("/tasks/", json={"title": "to complete"})
    assert status_ok(r.status_code)
    tid = r.json()["id"]

    r2 = test_client.patch(f"/tasks/{tid}/complete")
    assert r2.status_code == 200
    assert r2.json()["completed"] is True


def test_delete_task(test_client):
    r = test_client.post("/tasks/", json={"title": "to delete"})
    assert status_ok(r.status_code)
    tid = r.json()["id"]

    r2 = test_client.delete(f"/tasks/{tid}")
    assert r2.status_code in (200, 204)  # your endpoint returns 204

    r3 = test_client.get(f"/tasks/{tid}")
    assert r3.status_code == 404
