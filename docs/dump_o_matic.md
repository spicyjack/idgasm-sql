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
- `read_view(view_name)`
  - Invoked by: _Controller_
  - Purpose: Response to the _View_ sending `view_changed` to the _Controller_
  - Response: _View_ returns view data to the _Controller_
- `update_view(view_name)`
  - Invoked by: _Controller_
  - Purpose: When data in _DBTool_ (model) has changed
  - Response: _View_ calls `read_data(view_name)`

Controller methods
- `read_data(view_name)`
  - Invoked by: _View_
  - Purpose: Response by the _View_ after receiving a
    `updated_data(view_name)` message from the _Controller_
  - Response: _Controller_ Returns updated data for the _View_ to display
- `update_data(view_name)`
  - Invoked by: _View_
  - Purpose: Causes the _Controller_ to call `read_view(view_name)` using the
    view callback object
  - Response: _Controller_ calls `read_view(view_name)` to get the updated
    data from the _View_, and also decides whether or not _DBTool_ needs to be
    updated.  If _DBTool_ needs to be updated, calls the appropriate _DBTool_
    method
    - `create/update/read/delete`

- `create_successful`
  - Invoked by: _DBTool_
  - Purpose: Lets the _Controller_ know that a `create()` request was
    successful
  - Response: Updates _View_?
- `create_failed`
  - Invoked by: _DBTool_
  - Purpose: Lets the _Controller_ know that a `create()` request failed
  - Response: Updates _View_?
- `read_successful`
  - Invoked by: _DBTool_
  - Purpose: Lets the _Controller_ know that a `read()` request was
    successful, and returns the data requested
  - Response: Updates _View_?
- `read_failed`
  - Invoked by: _DBTool_
  - Purpose: Lets the _Controller_ know that a `read()` request failed
  - Response: Updates _View_?
- `update_successful`
  - Invoked by: _DBTool_
  - Purpose: Lets the _Controller_ know that an `update()` request was
    successful
  - Response: Updates _View_?
- `update_failed`
  - Invoked by: _DBTool_
  - Purpose: Lets the _Controller_ know that an `update()` request failed
  - Response: Updates _View_?

DBTool (Model) methods
- All _DBTool_ methods are invoked by the _Controller_
- `create(table_name, hash_with_table_info)`
  - Create a table using info read from another database
- `read_schema(database_object, table_name)`
  - Read schema from a database
- `read_data(database_object, table_name)`
  - Read data from a database
- `update(database_to_update, update_data)`
  - Add/update records to a database
- `delete(data_to_delete, table_name)`
  - Delete records from a database
  - Probably never be used for `dump_o_matic`

vim: filetype=markdown shiftwidth=2 tabstop=2

