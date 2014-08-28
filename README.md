<p align="center">
  <img src ="https://raw.githubusercontent.com/remirobert/Camembert/master/ressources/CamembertLogo.png"/>
  <h1 align="center">Camembert</h1>
</p>

Camembert is written in a **swift** toolkit for using sqlite3 easier. Is is available for **OSX** and **iOS**.

<h1 align="center">Installation</h1>

First you need to add a bridging-header to your project.
If it is already set to copy the contents of Bridging-header.h in yours.

```Objective-C
#import <UIKit/UIKit.h>
#import "sqlite3.h"

BOOL camembertExecSqlite3(void *ptrSqlite3, const char *request);
id camembertCreateObject(NSString *nameClass);
```

If you need to add one, follow these instructions:

- Go into the **settings** of your project in the category **build setting**.
- Search **Objective-C Bridging Header** with the search bar.
- Add the following line : **${YOURPROJ}Bridging-Header.h**
- Then copy the **Bridging-header.h** file, in your project.

<h1 align="center">Usage</h1>
