# instance folder

This folder is intentionally not a member of the rebuild process.

Can be used for capturing instance-level activity that cannot (or should not) be a step of the rebuild.

Typically the rebuild process is executed by the product owner role.

Use cases:

* CREATE ROLES/USERS statements
* CREATE/ALTER DATABASE statements
* intra-database data migration/propagation logic