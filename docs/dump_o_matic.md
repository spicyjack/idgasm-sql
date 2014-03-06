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
- `request_update`
  - Invoked by: _DBTool_
  - Purpose: Updates the _Controller_ with the status of a request; _DBTool_
    will include information about the successful request (request ID or type,
    or both)
  - Response: _Controller_ updates _View_ based on business rules/need
- `request_success`
  - Invoked by: _DBTool_
  - Purpose: Lets the _Controller_ know that a previous request was successful;
    _DBTool_ will include information about the successful request (request ID
    or type, or both)
  - Response: _Controller_ updates _View_ based on business rules/need
- `request_failure`
  - Invoked by: _DBTool_
  - Purpose: Lets the _Controller_ know that a previous request failed;
    _DBTool_ will include information about the failed request (request ID or
    type, or both)
  - Response: _Controller_ updates _View_ based on business rules/need,
    possibly lets user know something failed

DBTool (Model) methods
- All _DBTool_ methods are invoked by the _Controller_, and will cause
  _DBTool_ to invoke one or more of the `request_*` methods during processing
  (`request_update`), as well as after processing is complete
  (`request_success`/`request_failure`)
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

