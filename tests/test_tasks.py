def status_ok(code: int) -> bool:
    return code in (200, 201)


def test_health(test_client):
    r = test_client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_create_and_get_task(test_client):
    r = test_client.post("/tasks/", json={"title": "Write tests", "description": "Week 5"})
    assert status_ok(r.status_code), r.text
    created = r.json()
    assert created["title"] == "Write tests"
    assert created["completed"] is False

    r = test_client.get(f"/tasks/{created['id']}")
    assert r.status_code == 200
    fetched = r.json()
    assert fetched == created


def test_update_task(test_client):
    c = test_client.post("/tasks/", json={"title": "Old", "description": "d"}).json()
    r = test_client.put(
        f"/tasks/{c['id']}", json={"title": "New", "description": "dd", "tag": "w5"}
    )
    assert status_ok(r.status_code), r.text
    updated = r.json()
    assert updated["title"] == "New"
    assert updated["tag"] == "w5"


def test_complete_and_delete(test_client):
    c = test_client.post("/tasks/", json={"title": "Complete me"}).json()
    r = test_client.patch(f"/tasks/{c['id']}/complete")
    assert r.status_code == 200
    assert r.json()["completed"] is True

    r = test_client.delete(f"/tasks/{c['id']}")
    assert r.status_code == 204

    r = test_client.get(f"/tasks/{c['id']}")
    assert r.status_code == 404


def test_filters_search_tag_completed(test_client):
    test_client.post("/tasks/", json={"title": "Alpha test", "tag": "alpha"})
    test_client.post("/tasks/", json={"title": "Beta work", "tag": "beta"})
    t3 = test_client.post("/tasks/", json={"title": "Gamma done", "tag": "beta"}).json()
    test_client.patch(f"/tasks/{t3['id']}/complete")

    # search
    r = test_client.get("/tasks/?search=beta")
    assert r.status_code == 200
    titles = {t["title"] for t in r.json()}
    assert titles == {"Beta work", "Gamma done"}

    # tag filter
    r = test_client.get("/tasks/?tag=alpha")
    assert {t["tag"] for t in r.json()} == {"alpha"}

    # completed filter
    r = test_client.get("/tasks/?completed=true")
    assert all(t["completed"] is True for t in r.json())


def test_404s_and_validation(test_client):
    r = test_client.get("/tasks/999999")
    assert r.status_code == 404

    r = test_client.put("/tasks/999999", json={"title": "X", "description": "Y"})
    assert r.status_code == 404

    # validation: title required
    r = test_client.post("/tasks/", json={"description": "no title"})
    assert r.status_code in (400, 422)
