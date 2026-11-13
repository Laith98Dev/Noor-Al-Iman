# Noor Al-Iman: Quran Memorization Center App

Noor Al-Iman is a Flutter app for a Quran memorization center. Today the center keeps
attendance on paper sheets and each teacher tracks progress in a personal notebook, so
records get lost and supervisors can't easily see how a classroom is doing. This app puts
the daily work of the center into one shared system that every staff member can reach
from their phone.

This is our project for **Special Topics in Computer Science (Flutter and Dart Programming)**
at Amman Arab University, supervised by Ala Ali Hamel Abu Thawabeh.

## What the app does

The app has three roles, and each user only sees the functions of their role.

| Role | Main tasks |
|---|---|
| **Admin** | Manage students, staff, classrooms and the gift catalog, enroll students in classrooms |
| **Teacher** | Take daily attendance, record memorized verses with an evaluation, give gifts |
| **Supervisor** | Follow the classrooms they supervise through reports and student profiles |

The center's rules are applied automatically. A classroom can't take more students than
its capacity, a student with records can't be deleted (only marked inactive), and each
student's full history of progress, attendance and gifts is kept in one place.

## Tech stack

| Part | Technology |
|---|---|
| Mobile app | Flutter, Dart 3 |
| State management | Provider |
| Navigation | go_router |
| HTTP client | dio |
| Backend | PHP 8.2, Slim 4 REST API |
| Database | MySQL 8 |
| Authentication | JWT tokens, bcrypt password hashing |
| CI | GitHub Actions |

## Repository structure

```
app/          Flutter app (Android, Windows for testing)
api/          PHP REST API
  database/   schema.sql and seed.sql (demo data)
docs/         Phase 1 report, UI/UX designs and diagrams
  design/     screen designs and design system
  diagrams/   use case, navigation flow, architecture, Scrum, Gantt (draw.io + PNG)
.github/      CI and release workflows
```

## Project plan

We follow Scrum over 14 weeks in three stages.

| Stage | Sprints | Dates | Status |
|---|---|---|---|
| 1. Plan & Design | Sprint 0 | until 13 Nov 2026 | Done |
| 2. Develop | Sprints 1 to 3 | 14 Nov to 25 Dec 2026 | Next |
| 3. Test & Deliver | Sprints 4 and 5 | 26 Dec 2026 to 22 Jan 2027 | |

The full requirements, screen designs, data model and API design are in the
[Phase 1 report](docs/Noor_Al-Iman_Phase1_Report.pdf). Tasks are tracked as GitHub Issues
(T001 is issue #1, and so on) on the project board.

## How we work

- `main` holds the work of finished sprints, `develop` holds the current sprint.
- Each task gets its own branch and a pull request into `develop`, reviewed by a teammate.
- At the end of each sprint `develop` is merged into `main`.

## Getting started

Set-up steps for the app and the API will be added during Stage 2, as each part is built.

## Team

- Adam Alrefa'e
- Laith Al Haddad
- Yousef Hassan
