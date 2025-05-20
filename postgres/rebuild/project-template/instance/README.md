# instance folder

This folder is intentionally not a member of the rebuild process, yet.

Can be used for capturing instance-level activity that cannot (or should not) be a step of the rebuild.

Use cases:

* CREATE ROLES/USERS statements
* CREATE/ALTER DATABASE statements
* Intra-database data migration/propagation logic