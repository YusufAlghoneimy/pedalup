\# Smart Bike Rental App - PedalUp



Software Engineering (CSEN303) - GIU - Milestone 2



\## Team

| Name | ID | Role in team |

|------|----|--------------|

| <name> | <id> | Team leader |

| <name> | <id> | Member |

| <name> | <id> | Member |

| <name> | <id> | Member |

| <name> | <id> | Member |

| <name> | <id> | Member |

| <name> | <id> | Member |

| <name> | <id> | Member |



\## ERD

Editable diagram: \[erd.drawio](docs/erd.drawio)



!\[ERD](docs/erd.png)



Notation: crow's-foot (legend on the diagram). Every relationship has a name that reads parent -> child

(e.g. riders rides sessions) and a cardinality at both ends (1, 0..1, 0..N).

Each role has its own table: Rider -> riders, Admin -> admins, Company -> companies.

There is no unresolved many-to-many: a payment applies at most one discount (payments.discount\_id).

19 tables, 32 relationships.

\## Traceability: entities to user stories

| Entity | Justified by user stories |

|--------|---------------------------|

| riders | US-001, US-002, US-003, US-017, US-021 |

| admins | US-022 to US-028 |

| companies | US-029, US-030 |

| id\_verifications | US-002, US-024 |

| notifications | US-009, US-010, US-019, US-024 |

| stations | US-004, US-011, US-012, US-022 |

| docks | US-004, US-011, US-012 |

| bikes | US-005, US-006, US-007, US-023, US-026 |

| station\_alerts | US-025 |

| areas | US-004, US-010, US-028 |

| pricing\_rules | US-008, US-009, US-030 |

| subscription\_plans | US-015, US-030 |

| subscriptions | US-015, US-021 |

| sessions | US-006, US-008, US-009, US-011, US-012, US-021 |

| discounts | US-016, US-017, US-030 |

| payments | US-013, US-014, US-016 |

| blocks | US-006, US-010, US-028 |

| complaints | US-018, US-027 |

| maintenance\_tasks | US-026, US-027 |



US-020 (chatbot) and US-029 (dashboard) need no table of their own: the chatbot stores nothing

(it can open a report in complaints), and the dashboard is computed from sessions,

payments and subscriptions.



\## Database

\- DBMS: PostgreSQL <version>

\- Database name: smart\_bike\_rental

\- Scripts are in the schema/ folder; run them in numeric order on an empty database.



| Script | Purpose |

|--------|---------|

| 01\_create\_tables.sql | All 19 tables in dependency order: primary keys, UNIQUE keys, NOT NULL, DEFAULT`s and all 32 foreign keys with their `ON DELETE rules |

| 02\_constraints\_indexes.sql | Business-rule CHECK constraints, partial unique indexes (one active ride per rider and per bike), an index on every foreign key and query indexes |

| 03\_seed\_data.sql | Sample rows for every table (stations, docks, bikes, riders, rides, payments, ...) |



\### How to run (pgAdmin 4)

1\. Right-click \*Databases -> Create -> Database...\*, name it smart\_bike\_rental, save.

2\. Select the database, open \*Tools -> Query Tool\*.

3\. Open each script (folder icon) in numeric order and run it with \*F5\*.

4\. Refresh \*Schemas -> public -> Tables\*: 19 tables are listed. Script 03 ends by printing the row count of every table.

