---
layout: post
title:  Node Permission Bug with Docker Compose
date:   2023-08-30 09:29:00 -0500
categories: django node docker
---
When running Docker Compose for our project, which has a service for serving Python processes and another service for running Node processes, we started getting random permission errors like the following.

```
node    | Error: EACCES: permission denied, mkdir '/code/node_modules/.vite/deps_temp'
node    |     at Object.mkdirSync (node:fs:1349:3)
node    |     at runOptimizeDeps (file:///code/node_modules/vite/dist/node/chunks/dep-ca21228b.js:42881:14)
node    |     at Timeout._onTimeout (file:///code/node_modules/vite/dist/node/chunks/dep-ca21228b.js:42290:54)
node    |     at processTicksAndRejections (node:internal/process/task_queues:96:5) {
node    |   errno: -13,
node    |   syscall: 'mkdir',
node    |   code: 'EACCES',
node    |   path: '/code/node_modules/.vite/deps_temp'
node    | }
```

And:
```
npm WARN logfile Error: EACCES: permission denied, scandir '/root/.npm/_logs'
npm WARN logfile  error cleaning log files [Error: EACCES: permission denied, scandir '/root/.npm/_logs'] {
npm WARN logfile   errno: -13,
npm WARN logfile   code: 'EACCES',
npm WARN logfile   syscall: 'scandir',
npm WARN logfile   path: '/root/.npm/_logs'
npm WARN logfile }
npm ERR! code EACCESS
npm ERR! syscall mkdir
npm ERR! path /root/.npm/_cacache/tmp
npm ERR! errno -13
npm ERR! 
```

These errors didn't make much sense to us because the errors were random, and the user that the node service was running as should have been root. What we discovered was that we were running into an issue where any scripts run with `npm run` were switching to running the process as the owner of a path based on the owner of its nearest existing parent by using [infer-owner](https://www.npmjs.com/package/infer-owner). This behavior has now been [removed](https://github.com/npm/promise-spawn/pull/40) from NPM's dependency promise-spawn as of v5.0.0 and NPM version [v9.0.1](https://github.com/npm/cli/blob/latest/CHANGELOG.md#901-2022-10-26). The owner of our project's root folder was getting changed to a non-privileged user by our Django/Python process because we had set up that service to run as a generic app user that we created for security reasons. We're still not 100% sure which Python script/process was changing to the root folder to be owned by the generic app user. But this is why `npm run` switched to running by the user ID of the generic app user since the generic app user didn't exist in the node container.

We were also puzzled by why the file and directory owner and group changes persisted for our project directories. Through trial and error, we discovered that Docker stores owner and group changes using Mac's extended attributes on a Mac host. When we looked at the project directories' extended attributes by running `xattr .` on our Macs, we discovered there was an attribute named `com.docker.grpcfuse.ownership` when we printed the value of the attribute using `xattr -p com.docker.grpcfuse.ownership .` the result `{"UID":33,"GID":33,"mode":10000}` showed that was where Docker was storing the owner changes. After deleting the attribute with `xattr -d com.docker.grpcfuse.ownership .`, the directory's owner returned to being root.

Our current solution is to ensure we are running our Python/Django service as the same user as our Node service is using. Right now, we're just using root for both services since that's straightforward and since this is only for local development. However, upgrading NPM could also fix this or switch to creating an app user with the same ID in both services.

My hope with this blog post is that others might find it and save some time in debugging and figuring out a solution. Our team learned a lot about Docker and Node in the process.