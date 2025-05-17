# appnext

1. The purpose of this folder is to drive the rebuild only.
1. This schema folder should not have object scripts.

This schema would only be used in database migration target in situations where the pull request meets these conditions:
1. app schema object(s) been created or modified
1. data schema object(s) may have been created (but not modified), and
1. it is required to have zero-downtime for the database migation

## Example

### Given:

Objects in production:
1. table: data.some_table
1. function: app.some_function (with dependency on data.some_table)

Source control change:
1. new table: data.some_other_table
1. modified function: function app.some_function has additional dependency on the new table

### Database Migration:

Users
1. privileged database user (database_admin_role), search_path is not relevant
1. database owner user (database_owner_role), the existing search_path = "data", "app"
1. application connection user (app_connection_role), the existing search_path = "app"

Migration script similar to:
````
$ psql database_name database_admin_role  -- connect as privileged user
# set role database_owner_role            -- switch role to database owner
create table some_other_table ...         -- table will be created in data schema
set search_path = "appnext"               -- change session search_path
create or replace some_function ...       -- function will be created in appnext schema
alter user app_connection set search_path = "appnext", "app";
````

### Application Migration

Restart the application service(s) that are dependent upon connections to the database with app_connection_role. For new app_connection_role sessions, some_function() will now utilize appnext.some_function() and nothing else changes are is invalidated. It may be necessary to flush existing connection pools to force the use of the new search_path. Or, it can just happen naturally.

### Followup

Eventually you will want to migrate appnext schema objects into the app schema in the target database before the next migration.