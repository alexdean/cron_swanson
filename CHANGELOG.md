# Changelog

## 0.3.4 : "Dear frozen yogurt, you are the celery of desserts. Be ice cream or be nothing." : Jan 1, 2021

Note that gem doesn't currently work with ruby 3.

## 0.3.3 : "There has never been a sadness that can’t been cured by breakfast food." : May 13, 2020

Remove 1 annoying `puts` statement.

## 0.3.2 : "I regret nothing. The end." : November 4, 2019

Important bugfix: Previous versions would generate invalid schedule strings
for intervals less than 1 hour in length.

## 0.3.0 : "Any dog under 50 pounds is a cat and cats are useless." : November 4, 2019

New feature:

  * Support for seed strings, to allow the same job to have distinct schedules
    in various apps.

Breaking changes:

  * `whenever` integration changed from class methods to instance methods.
  * Some methods were renamed.

## 0.2.0 : "Under my tutelage, you will grow from boys to men." : November 3, 2019

Improvements in whenever integration.

  * Jobs are scheduled based on their contents, not their source location.
  * Added support for `roles`.

## 0.1.0 : "I'm not interested in caring about people." : November 1, 2019

Initial release
