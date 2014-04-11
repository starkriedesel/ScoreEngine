This is a [CCDC](http://nationalccdc.org/) style score engine which [SMU](http://www.smu.edu) team uses to practice.
It is designed to function similarly to the real score engines in use at regional and national levels plus provide additional feedback to help teach new students.

The code is split into a few main parts:

1. Service listing
2. Messaging system
3. Debug tools
4. Background workers
5. BETA: Server Manager

# Prerequisites

To setup the score engine in a fresh environment here is a list of necessaary softwares:
* [RVM](http://rvm.io/)
* MySQL >= v5
* Optional: [LibVirt](http://libvirt.org/) for use with the Server Manager

# Supported Service Protocols

See lib/workers for implementations details and parameter defaults

* HTTP(S)
* FTP(S)
* SFTP
* DNS
* IMAP
* LDAP
* MySQL
* SMTP
* SSH
* Netcat (ie. generic socket connection)

Each worker has a parameter list at the top of each implementation and includes descriptions and default values.

Most are defined by some connection settings, a request or query string (url, domain, email message, etc) and some expected output.

Typically ouput is checked using one of three methods:

1. If the check starts and ends with / then it is regex
2. If the check looks like an MD5 then the response is hashed and compered
3. Anything else is a conains? lookup. Ie. if the response contains the exact string specified then it is valid.

While all basic requests with each protocol works read each worker carefully to understand exactly what it is capable of.
LDAP for example has very specific login capabilities. Don't be afraid to open the ruby docs for the library used for a worker.

# Service Listing

Teams can be created by the administrator. Users can self register and are put in the nil team ("Team None" or team #0).
Although services can be applied to team 0 it is suggested to create at least one team and move users to the correct team after they register.
Teams have a name, domain and DNS entry. If any service parameter contains the string '{domain}' (without quotes) then that team's domain will be inserted.
Additionally, any domain that needs to be looked up to complete a service request will be sent to the team's DNS server.
If a team is not given a DNS server then the score server's default name server will be used.

A service can be in one of three states:
* Running - green - everything is a go, no problems
* Error - orange - there was a problem which is preventing it being scored as up but the service is not neccessarily down. There will be a description of the problem
* Down - red - the request was refused. The score engine cannot even connect to the service. Again there will be a description of the problem.
* Off - grey - service is not being checked. Don't worry, no points get lost :)

The errors given to the team is pretty much exactly the error the server recieved. Many services (or libraries) report back ambigous or strange error string.
The intention is to provide the team what a customer might say in a real situation (service X is down and gave an error Y, I don't know what that means, fix it).

Administrators additionally get the Debug button which allows a step by step of what the server did including any DNS resolutions.
The output here is invaluable in resolving problems while a simulation is live (is it my fault or did blue team screw it up?).

The default service page lists all services for a team with some diagnostic info.
Administrators also have access to the overview where all teams/service statuses are given quickly.
Clicking on a given service shows the specific page with a history.
Administrators can delete history (all or one log at a time).
The total uptime is also given and is computed as (ticks running) / (total ticks).
Administrators can also turn services on/off which allow for pausing old serivces or setting up services before they are scored.

All service statuses (including uptime) are updated in real time.
There is also a graph view of service up time.

Checkout config/settings.yml for details about tick speed (how often between server requests).

# Messaging System

This system is in place to allow two way communication between teams and administrator.
Users do not send/recieve mail individually but the enitre team as a whole.

New messages are check in the background on all pages.
When the mail icon turns blue there is unread mail.
Messages are marked as read by cookies. Logging out and in again will mark all as unread. One user viewing a message will not update all users for that team.

# Debug Tools

There is a tools list which allows for some basic DNS and hash checking.
This is available to test what the server sees from the teams.
Teams do have access to this by default.

# Background Workers

See "Supported Service Protocols" above for implememtation details of the protocol workers.
The daemon is in lib/daemon.rb and is started using the `$ rake engine:start`.
The daemon can then be stopped using `$ rake engine:stop`.
Daemon status is given by the color of the "ScoreEngine" text in the top left of the web page (green=running, red=off).

One of the tools listed (only for admin) is the daemon log.
Use this to debug problems with the daemon such as missing logs or strange timeouts.

All requests (for all teams) occurr in individual threads but are time constrained such that the ticks never last too long.
Incorrect imeouts can happen if the tick time is less than 10 seconds.
30 second tick time is recomended minimum for multiple teams running many services.
See config/settings.yml for daemon settings.
Copy the file into config/settings.local.yml to edit values without dirting the git repo.

The first tick or two of the daemon can throw ruby errors such as Class not Defined.
Don't worry, just read the daemon log just after starting the server.
The daemon should not crash and should succeed without error by the thrid tick.
The problems have to do with Rails autoloading classes.
Just delete any logs which came back incorrectly.
You can also clear all logs in the system simultaneously using `$ rake services:clear`.

You can also turn services all on or off at once using `$ rake service:[on|off] {teamid}` where teamid is an optional number to specify just 1 team.

#BETA: Server Manager

This is barely tested and not considered ready yet.
The goal of the Server Manager is to allow control over a virtual CCDC environment.
In a real CCDC event the teams would be able to easily start/stop/restart machines at will.
We tend to use virtualization to practice so we don't have to deal with so much hardware.

The Server Manager aims to abstract interactions with the virtualization environment to support as many systems as possible
Right now only LibVirt using VirtualBox has been tested and it relies on libvirt to use TCP with no encryption.
Eventually this manager will support many more platforms supported by LibVirt (QEMU, VMWare / VSphere, Xen, Hyper-V).

Also in alpha support now is AWS integration.
Very few commands are supported by AWS but this is a good option for cheap/temporary virtual networks.

LibVirt + VirtualBox currently supports (beta status):
* Start / Stop / Restart
* Pause / Resume
* Create / Restore from snapshot
* Screenshot (every 3 seconds - this really likes crashing the server...)
* Multiple servers

AWS currently supports (alpha status):
* Start / Stop / Restart

Read the commented section of config/settings.yml and create a settings.local.yml with the relevent sections to enable Server Manager.

