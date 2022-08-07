const { CloudFrontClient, CreateInvalidationCommand } = require("@aws-sdk/client-cloudfront");
const { CodePipelineClient, PutJobSuccessResultCommand, PutJobFailureResultCommand } = require("@aws-sdk/client-codepipeline")


exports.handler = async function (event, context) {

    var distributionId = process.env.cloudfront_distribution_id;
    var region = process.env.cloudfront_region;


    // Retrieve the Job ID from the Lambda action
    var jobId = event["CodePipeline.job"].id;
    // jobId = "2d20ad91 – AWS Lambda";
    console.log("JobID: " + jobId);
    // Set up CloundFront
    const client = new CloudFrontClient({ region: region });
    var date = Date.now();
    var input = {
        DistributionId: distributionId,
        InvalidationBatch: {
            Paths: {
                Quantity: 1,
                Items: ["/*"]
            },
            CallerReference: date
        }
    }

    const command = new CreateInvalidationCommand(input);



    // Notify CodePipeline of a successful job
    var putJobSuccess = async function (message) {
        const codepipeline = new CodePipelineClient({ region: region });
        var params = {
            jobId: jobId
        };
        const jobSuccessCommand = new PutJobSuccessResultCommand(params);
        try {
            const jobSuccessData = await codepipeline.send(jobSuccessCommand);
            context.succeed("Cloudfront Distribution Invalidated");
            console.log(jobSuccessData);
        } catch (error) {
            context.fail(error);
            console.log(error);
        }

    };

    // Notify CodePipeline of a failed job
    var putJobFailure = async function (message) {
        const codepipeline = new CodePipelineClient({ region: region });
        var params = {
            jobId: jobId,
            failureDetails: {
                message: JSON.stringify(message),
                type: 'JobFailed',
                externalExecutionId: context.awsRequestId
            }
        };
        const jobFailureCommand = new PutJobFailureResultCommand(params);
        try {
            const jobFailureData = await codepipeline.send(jobFailureCommand);
            context.succeed("Successfully Updated CodePipeline with failure state.");
        } catch (error) {
            context.fail(error);
            console.log(error);
        } finally {

            // console.log("Success!")
        }

    };


    try {
        const data = await client.send(command);
        console.log("Data: ", data);
        const codepipeline = new CodePipelineClient({ region: region });
        var params = {
            jobId: jobId
        };
        const jobSuccessCommand = new PutJobSuccessResultCommand(params);
        try {
            const jobSuccessData = await codepipeline.send(jobSuccessCommand);
            console.log("Job Success Data: ", jobSuccessData)
        } catch (error) {
            console.log(error);
        }
    } catch (error) {
        const codepipeline = new CodePipelineClient({ region: region });
        var params = {
            jobId: jobId,
            failureDetails: {
                message: JSON.stringify("Failure to invalidate."),
                type: 'JobFailed',
                externalExecutionId: context.awsRequestId
            }
        };
        const jobFailureCommand = new PutJobFailureResultCommand(params);
        try {
            const jobFailureData = await codepipeline.send(jobFailureCommand);
            context.succeed("Successfully Updated CodePipeline with failure state.");
        } catch (error) {
            context.fail(error);
            console.log(error);
        }
    }

};

