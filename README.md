### SdbEx

A Ruby/Tk application to view AWS SimpleDB data.

`sdbex` is still under development.  If you want to try it out, try these steps:

* Clone the repo: 

        git clone git@github.com:plutino/sdbex.git
        
* `cd` to the application directory and install dependencies:

        bundle install
        
* Run the app in commandline:

        bundle exec bin/sbdex
        
* Enjoy and [report](https://github.com/plutino/sdbex/issues) any bugs.

#### TODO (prioritized)

* Edit items
* Reset changes (attribute, item, all)
* Save item changes to SimpleDB
* Load items in batches
* Stand-alone app release
* Items with multiple attribute values