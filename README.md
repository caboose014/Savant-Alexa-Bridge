# Savant-Alexa-Bridge

This project is to integrate Alexa on the Amazon Echo with Savant home automation systems.


### A few notes when creating your RacePoint config:
* Words in the name of any custom workflow should be separated by spaces only. 'OpenGate' should be written as 'Open Gate'.
* Service Aliases should be named with spaces between words. 'MediaPlayer' should be named as 'Media Player'.
* Only custom workflows that you have enabled to show on the UI will work. (`Tools > Review > Custom Workflow usage...`)
* Keep service alias's simple, and unique. Otherwise Alexa may have problems understanding your requests
* Disable any A/V services you are not using (i.e, disable any audio only services if you dont use them)

### To do:
* ~~Enable support to run custom workflows~~
* Investigate enabling Environmental services. Some services such as lighting may have an existing Alexa Skill available, check the library to see.
* Look at a generic zone 'Turn off' command, rather than be having a service specific turn off command
* ~~Introduce cli switches to only enable specific zones~~

### Using Alexa
* Services are automaticly discovered from the currently active configuration on the host. Just tell Alexa to 'Discover devices' once the script is up and running
* A single instance of the script is currently limited to 64 services/workflows. This is a limitation on Amazon's side of things. So if you have more services/workflows than this, you will need to run multiple scripts and break out the zones you want to use
* To command Alexa to turn on or off a service just say 'Turn on [service alias] in the [zone]'. You can ommit 'In The' if you wish and just say 'Turn on [service alias][zone]'
* Command line arguments can be used to manipulate the script:
  * `-z "Lounge,Master Bedroom,Kitchen"` Comma seperated array of zones to discover. There must be no space after the `,`
  * `-p 4567` Run the script on a different port. If you are starting multiple scripts, **The port number must be different for each instance of the script**
  * `-r` Don't append the zone name to the serivice alias. This is handy if you are only discovering services for one zone in your whole config.
* When you upload a new config with new/different services you have to restart the script manually for it to discover changes

### Important notes:
* Currently only tested on the Savant Pro Host
* This is currently unsupported on the SCH-2000 host as there is a bug in Ruby on this host that Savant are not going to resolve. If people want support on this host, please contact me and I can give you information on opening a support case with Savant. Hopfully if enough pople complain, we can get this fixed.
* When you look at your list of devices on the Alexa app, you will see they populate as Philips Hue White bulbs. This is normal.
* Integration is currently limited to 64 services/workflows.

### Check out a live demo here:
[![Alexa/Savant Integration](https://img.youtube.com/vi/DSympA6xToc/0.jpg)](https://www.youtube.com/watch?v=DSympA6xToc)
