Contributing
============

Reporting bugs
--------------

If you find a bug in nanoc, you should report it! But before you do, make sure you have the latest version of nanoc (and dependencies) installed, and see if you can still reproduce the bug there. If you can, report it!

When reporting a bug, please make sure you include as many details as you can about the bug. Some information that you should include:

* The nanoc version (`nanoc --version`)
* The `crash.log` file, if relevant

Submitting Patches
------------------

If you want to submit a pull request, please review the following few guidelines:

* If your pull request is a **bug fix**, submit it on the latest release branch. At the moment of writing, this is `release-3.4.x`. This ensures that the bug fix comes in the next patch release.

* If your pull request is a new **feature** or extends an existing feature,  submit it on the `master` branch.

In both cases, make sure that your changes have **test cases** that cover the bug fix or the new/changed functionality.

Also note that **backwards compatibility** must be retained. This means that you cannot simply modify a feature to work in a different way. What you can do, is add an option to make it work in a different way, but do double-check with me (@ddfreyne) first.
