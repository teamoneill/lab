# instance folder

This folder is intentionally not a member of the rebuild processing.

Can be used for capturing instance-level activity that cannot (or should not) be a member of the rebuild processing.

Typically the rebuild process is executed by the database owner, not a super user.

Use cases:

* CREATE ROLES/USERS statements
* CREATE/ALTER DATABASE statements
* intra-database data migration/propagation logic