mvn clean install -f parent-pom/parent.pom.xml
mvn clean install -f parent-pom/parent-jar.pom.xml
mvn clean install -f parent-pom/parent-war.pom.xml
cd common
mvn clean install
cd ../sandbox
mvn clean package
cd ..
