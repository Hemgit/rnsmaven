## Pre-requisites:

#### Step-1: First choose the Region where you would like to create a resources

#### Step-2: Create keypair with name 'batch#'

#### Step-3: configure aws with ACCESS_KEY and SECRET_KEY.
    Install the aws cli and configure it
    $ aws configure

#### Step-4: Set the following Variable Values in variables.tf file
    - region
    - keypair_name
    - availability_zone


## Tomcat Config:

#### Step-1: Remove the restriction to access manager app from Remote

    - TOMCAT_HOME/webapps/manager/META-INF/context.xml

    - cp ./files/tomcat/manager/context.xml /opt/tomcat/webapps/manager/META-INF/context.xml

#### Step-2: Add the Users to access the Tomcat Manager App

    - TOMCAT_HOME/conf/tomcat-users.xml

    - cp ./files/tomcat/conf/tomcat-users.xml /opt/tomcat/conf/tomcat-users.xml



## Deploying the App to Tomcat Server:

#### Step-1: Clone the student app

        $ git clone https://gitlab.com/rns-app/student-app.git

        $ cd studentapp

#### Step-2: Build the project using Maven

        $ mvn clean package

#### Step-3: Deploy the war file to tomcat

    - copy the target/*.war /opt/tomcat/webapps/student.war

        $ cp target/*.war /opt/tomcat/webapps/student.war


## Configure Proxy Server:

- student should be routed from the nginx to the tomcat server
    - Define location directive with /student in nginx.conf
    - proxy_pass TOMCAT_SERVER_URL/student

    Platform Provisioning: (Shell Scripting)
    # Step 3 - Install and Start the maria DB server
    # Step-4 - Load the schema of the project (Creating DB and Tables)

    Integration of App with DB server:
    # Step-5 - Collect the DB Properties
                (IP, Port, UN, Pwd, DB Name)
    # Step-6 - add DB properties in TOMCAT_HOME/conf/context.xml file
    # Step-7 - Load the DB driver in TOMCAT_HOME/lib/
    # Step-8 - Restart the Tomcat Server
    # Step-9 - Test the Application by using App Server URL.
