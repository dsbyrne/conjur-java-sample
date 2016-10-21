# conjur-java-sample
--------------------
## Setup
Scripts have been provided to automate the setup. It is recommended that both scripts authenticate as the same Conjur user.
### Scripts
|step|script|description|where to execute|
|-|-|-|-|
|1|`load_policy.sh`| Loads [an application policy](conjur/app.yml) into Conjur using the Conjur CLI. This can be run from any machine, and requires the Conjur CLI is currently logged in as a member of the `security_admin` group. | Anywhere with the CLI installed |
|2|`setup_cli.sh` _OR_ `setup_curl.sh`| Adds dummy values to the variables defined within the [application policy](conjur/app.yml). Creates a host factory token from the [policy's host factory](conjur/app.yml). Using this host factory token, it then creates a host identity and writes Conjur configuration to disk. The example Java application will require this configuration. These two scripts perform the same operations (for educational purpose), one using the Conjur CLI, the other using curl. Only one of these scripts is required to be run.| From the machine running the application |
## Building
This example application is built using Maven. It requires the [Conjur Java API](https://github.com/conjurinc/api-java) is installed. With all dependencies installed, run `mvn package` from the root directory.
## Running
Run the application with `java -jar target/conjur-java-secrets-1.0-SNAPSHOT.jar`