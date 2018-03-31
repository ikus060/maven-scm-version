# maven-scm-version

This project handle managing version for Maven projects based on SCM metadata. Instead of defining the version in `pom.xml`, this project will provide a version number based on current SCM state. This project gets its inspiration from [setuptools_scm](https://github.com/pypa/setuptools_scm) for Python.

Usually, the version number of maven project is kept in `pom.xml` in a static way. Basically, the users need to update the `pom.xml` file for every release. With continuous integration taking more space, that way of working is not flexible enough.  It doesn't follow [continuous integration principle](https://www.slideshare.net/wakaleo/continuous-deliverywithmaven/12) where any revision may be promoted to production environment. That's where maven-scm-version come to the rescue.

## How to use maven-scm-version

In your `pom.xml` you need to change the `<version>` to make use of [`${revision}`](https://maven.apache.org/maven-ci-friendly.html).
```
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example.project</groupId>
  <artifactId>ci-friendly-project</artifactId>
  <name>CI Friendly Project</name>
  <version>${revision}</version>
  ...
</project>
```
Next time you need to compile your project, you can do so like this:
```
export REVISION="$(curl https://raw.githubusercontent.com/ikus060/maven-scm-version/master/version.sh | bash -)"
mvn -Drevision=$REVISION clean package
```
Since your goal is to setup continuous integration pipeline, you should make use of this command line in your preferred CICD tools like Jenkins or Gitlab-CI. Here's an example for `.gitlab-ci.yml`:
```
image: maven:3-jdk-7

variables:
  MAVEN_OPTS: "-Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=WARN
               -Dorg.slf4j.simpleLogger.showDateTime=true
               -Djava.awt.headless=true
               -Dmaven.repo.local=.m2/repository"

# Cache downloaded dependencies and plugins between builds.
cache:
  paths:
    - .m2/repository

stages:
  - test
  - deploy

before_script:
- export REVISION="$(curl https://raw.githubusercontent.com/ikus060/maven-scm-version/master/version.sh | bash -)"
- echo "REVISION=$VERSION"

test:
  stage: test
  script:
  - mvn -B -Drevision=${REVISION} clean verify
  
deploy:
  stage: deploy
  script:
  - mvn -B -Drevision=${REVISION} -DskipTests clean install deploy 

```

## Version number scheme

By default, maven-scm-version take 3 things in consideration: 

1. the latest tag
2. the distance to the latest tag (e.g. number of commit since latest tag)
3. workspace state (e.g.: uncommitted changes)

Then, use that information to provide a version number following this principle:

* no distance and clean:
  * {tag}
* distance and clean:
  * {next_version}-{distance}-g{revision hash}
* no distance and not clean:
  * {tag}-dYYMMDD
* distance and not clean:
  * {next_version}-{distance}-g{revision hash}.dYYMMDD
  
## Limitation

Current implementation only support git scm.

## Background Story

As of today, maven is not well designed for continuous integration / continuous delivery (CI/CD).

* The `-SNAPSHOT` is everything but useful in CI/CD. It doesn't provide traceability required if the revision is promoted to production.

* The maven-release-plugin is even worst. It required manual intervention to generate the release.  I've also read an [article](https://www.cloudbees.com/blog/new-way-do-continuous-delivery-maven-and-jenkins-pipeline) recommending generating a new release commit for every commit. That makes your git repository clutter and doesn't help traceability.

* The [buildnumber-maven-plugin](http://www.mojohaus.org/buildnumber-maven-plugin/) is closer to what we need. Its biggest disadvantage is `${buildnumber}` cannot be directly used in the `<version>` tag. So we need to work around that by changing the artifacts final name and it's metadata. Maven doesn't provide good enough integration to change the version on the fly. 

* The `pom.xml` required version tag. That where the `${revision}` come handy.

By using shell script, you are not restricted to use this script only for Maven projects. You may use the same script to generate versions of all sorts of projects in a similar way. It's overcome the limitations of Maven without changing what you are used. It leverage the feature provided by making use of `${release}` property.
