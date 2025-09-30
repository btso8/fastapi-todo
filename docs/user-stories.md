# 📋 User Stories & Acceptance Criteria

## Functional Requirements

| ID  | User Story | Acceptance Criteria | Priority |
|-----|------------|---------------------|----------|
| US1 | As a user, I want to create a new task so that I can track what I need to do. | - [ ] Given I POST `/tasks` with valid JSON, Then a new task is saved and returned with an ID.<br> - [ ] Given I POST with missing/invalid data, Then I get a `422` error. | MUST |
| US2 | As a user, I want to list all tasks so that I can see what I need to do. | - [ ] Given I GET `/tasks`, Then I see all tasks with correct fields.<br> - [ ] Given there are no tasks, Then I get an empty list. | MUST |
| US3 | As a user, I want to update a task so that I can correct or change details. | - [ ] Given I PUT `/tasks/{id}` with valid JSON, Then the task is updated and returned.<br> - [ ] Given I update a non-existent task, Then I get a `404`. | MUST |
| US4 | As a user, I want to delete a task so that I can remove things I don’t need. | - [ ] Given I DELETE `/tasks/{id}`, Then the task is deleted.<br> - [ ] Given I delete a non-existent task, Then I get a `404`. | MUST |
| US5 | As a user, I want to mark a task as complete so that I know it’s finished. | - [ ] Given I PATCH `/tasks/{id}/complete`, Then the task status changes to “completed”.<br> - [ ] Given I try to complete a non-existent task, Then I get a `404`. | MUST |
| US6 | As a user, I want to search tasks by keyword so that I can quickly find specific tasks. | - [ ] Given I GET `/tasks?search=keyword`, Then only tasks with keyword in title/description are returned. | SHOULD |
| US7 | As a user, I want to tag tasks so that I can group them by category. | - [ ] Given I POST `/tasks` with a tag, Then the task is saved with that tag.<br> - [ ] Given I GET `/tasks?tag=work`, Then only “work” tasks are returned. | SHOULD |

---

## Non-Functional Requirements (NFRs)

| ID   | User Story | Acceptance Criteria | Priority |
|------|------------|---------------------|----------|
| NFR1 | As a user, I want the system to respond quickly so that I don’t experience delays. | - [ ] API requests respond in < 200ms under normal load. | MUST |
| NFR2 | As a system owner, I want data to be secure so that sensitive info is protected. | - [ ] All traffic uses HTTPS.<br> - [ ] Data in RDS is encrypted at rest. | MUST |
| NFR3 | As a system owner, I want the app to be reliable so that users trust it. | - [ ] System uptime ≥ 99.9%.<br> - [ ] Health check endpoint (`/health`) always available. | MUST |

---

## Notes
- **MUST** = essential for MVP & assessment.  
- **SHOULD** = nice-to-have; delivered if time allows (helps with distinction grade).  
- Each Acceptance Criterion will be tested via **Pytest**, validated in **Swagger UI**, and evidenced with screenshots/logs in the Evidence Pack.  
