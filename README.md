# Lambda Go SDLC Workflow

![license](https://img.shields.io/github/license/mashape/apistatus.svg)
![Go](https://img.shields.io/badge/Go-1.x-blue.svg)
![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-blue.svg)

This repository is a working example of how a project can start with a
Lambda function written using Python and added inline into a
CloudFormation template for bootstrapping, then converted into a Go
application for long-term maintenance.

## What is this craziness?  Why do this?

Well, young pup, this is the magic of The Cloud.

One of the best things about CloudFormation is that you can codify your
infrastructure, and a Lambda function can be described as pure
infrastructure.  However, you are limited in the languages you can write
for your Lambda function and how you deploy it to AWS.  CloudFormation
allows for a Lambda function to be specified inline into the
CloudFormation template, but this adds a maintenance issue because the
code can no longer be tested outside of CloudFormation.  This ruins the
SDLC workflow.  While Lambda's support of Go is great, you cannot specify
a Go app inline into a CloudFormation template because it is a compile
language and the artifact must be contained within a zip file.

Sometimes people want to control where their artifact is loaded from,
sometimes not.  When you specify a Lambda function inline into a
CloudFormation template, the code artifact ends up being stored in a
bucket that AWS controls.  This transfers a lot of security risk to AWS
and out of your hands because you don't have to manage an S3 bucket for
your artifacts.  Best of all, it's free.  So let's take advantage of this
benefit and deploy our Go apps there.

Ah, but wait.  Now there's a two-step process.  First we have to define
the Lambda function and then we have to upload a code artifact to AWS's
S3 bucket.  This is what this project solves in three phases: initialize,
prepare, deploy, and test.  This provides a complete SDLC workflow for
developers.

* Initialize

  The Lambda function is declared as a Python runtime into the
  CloudFormation template, but this is just a stub for your actual
  application.

  This is done via `make init`.

* Prepare

  Then you modify the Lambda configuration out-of-band and update it to
  a Go runtime.  Your Lambda function is now in a half-baked state, where
  it expects a Go app, but it deployed with Python code.

  This is done via `make prepare`.

* Deploy

  Now deploy the Go app artifact to the Lambda function.  Your Lambda is
  now ready to serve requests.  From now on, the iteration of the code
  happens in this phase.  There is no relaunching or updating of the
  infrastructure unless the architecture changes (e.g. new IAM role
  permissions).

  This is done via `make deploy`.

* Test

  Testing is easy, but it happens as both a local (fast) test and as
  an end-to-end (slower) test.  The Lambda function can be tested as
  well as the Go application itself.

  This is done via `make test-stack` and `make test`.

## Motivation and Benefit

There are 3 motivations here: cost, deployment, and development.

* Cost/Speed

  When using AWS Lambda, the speed of your application and its memory
  usage will directly relate to the cost of the service.  Even this simple
  Python application takes about 200ms to run, and AWS
  bills in 100ms increments.  In contrast, this Go application takes 1ms
  to run.  We have another 99ms of headroom being billed that could be
  used to add business value to our customers.  Now that's value.

* Deployment

  Go application are bundled as a single static binary, with all of its
  dependencies (i.e. libraries) included, or vendored in.  This makes
  deployment as simple as copying the artifact to the server and testing
  it.  Also, testing the artifact is simple because Go binaries can be
  compiled for all operating systems (e.g. a Linux binary can be created
  on a MacOS machine).

* Development

  Go is a simple language, it makes readable code, and is fun to write.
  Opinions vary, but this is mine.  I also like ruby, vim and other
  contentious things.

The biggest benefit of this architecture is that the parts that change
the most are contained to within the function code itself, and the
infrastructure stays relatively static for its lifetime.  By separating
these pieces, the project will be more stable and permission structure
(separation of duties) can be implemented if that is an organizational
goal.

## But What About Business Continuity?

tl;dr Repeat phases _Initialize_ and _Prepare_.

If the Lambda function is destroyed at any time, it can be rebuilt
quickly.  The initial infrastructure is going to bootstrap itself
as the stubbed Python application, but you can then redeploy the
Go application quickly.  Since this is all held in the same Git
repository, it will be tagged and versioned appropriately.

