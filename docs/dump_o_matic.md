# Dump-O-Matic #

## Program control flow ##
- After the program starts, a "controller" object is created, then control is
  passed to it
  - `$controller->run`
- Controller sets up the other objects, and passes callbacks to them from
  itself as needed
- Controller object will then pull data from the model, and call
  `update_view()` on the view
- View will call 

## Object behaivor ##
View object methods
- `update_view(view_name)`
  - Invoked by the controller when the model has changed, causes the view to
    call `read_data(view_name)`
- `read_view(view_name)`
  - Invoked by the controller in response to the view sending `view_changed`
    to the controller; returns view data to the controller

Controller object methods
- `view_changed(view_name)`
  - invoked by the view, causes the controller to call
    `read_view(view_name)` using the view callback object
  - decides whether or not the model needs to be updated
- `read_data(view_name)`
  - Called by the view in response to the view receiving a
    `update_view(view_name)` message from the controller
  - Returns updated data for the view to display

Model object methods
- `read(database_to_read_from)`
  - Read records from a database
- `update(database_to_update, update_data)`
  - Add/update records to a database
- `delete(data to delete in model, from view)`
  - Delete records from a database

vim: filetype=markdown shiftwidth=2 tabstop=2

