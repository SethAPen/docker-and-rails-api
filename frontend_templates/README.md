## Setting up a React in Docker development environment

First initialize some React tooling with [create-react-app](https://github.com/facebook/create-react-app)

Next add the provided files to the root of the create-react-app folder.

Adjust the configuration as you see fit, but the defaults should be enough.

Don't forget to add some yarn commands to deploy your client image to Docker Hub.

Example:

```json
"deploy": "docker build -t ${USER_NAME}/${PROJECT_NAME} . && docker login && docker push ${USER_NAME}/${PROJECT_NAME}"
```
Note: -t is a flag that allows you to tag your image build, that tag will be the name used when pushing to Docker Hub.
