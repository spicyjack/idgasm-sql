# Dump-O-Matic #

## Program control flow ##
- After the program starts, a "controller" object is created, then control is
  passed to it
  - `$controller->run`
- _Controller_ sets up the other objects, and passes references to itself to
  the other objects
- _Controller_ object will then pull data from _DBTool_ (the model), and call
  `update_view()` on the view
- View will call ???

## Object Methods/Messages ##

View methods
- `update_view(view_name)`
  - Invoked by the _Controller_ when data in _DBTool_ model has changed,
    causes the _View_ to call `read_data(view_name)`
- `read_view(view_name)`
  - Invoked by the _Controller_ in response to the _View_ sending
    `view_changed` to the _Controller_; returns view data to the _Controller_

Controller methods
- `view_changed(view_name)`
  - invoked by the _View_, causes the _Controller_ to call
    `read_view(view_name)` using the view callback object
  - decides whether or not _DBTool_ needs to be updated
- `read_data(view_name)`
  - Called by the _View_ in response to the _View_ receiving a
    `update_view(view_name)` message from the _Controller_
  - Returns updated data for the _View_ to display

DBTool (Model) methods
- `create(table_name, hash_with_table_info)`
  - Create a table using info read from another database
- `read_schema(database_object, table_name)`
  - Read schema from a database
- `update(database_to_update, update_data)`
  - Add/update records to a database
- `delete(data_to_delete, table_name)`
  - Delete records from a database

vim: filetype=markdown shiftwidth=2 tabstop=2

