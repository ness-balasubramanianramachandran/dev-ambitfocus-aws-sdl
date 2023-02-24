{
  "Comment": "Step Function which orchestrates the creation and destruction of a CalcEngine cluster",
  "StartAt": "CreateNamespace",
  "States": {
    "CreateNamespace": {
      "Comment": "Start the workflow by creating a namespace or verify if namespace is created.",
      "Type": "Task",
      "Next": "IsNamespaceReady",
      "Resource": "${CREATE_NAMESPACE_LAMBDA_ARN}",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "MaxAttempts": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Teardown"
        }
      ]
    },
    "IsNamespaceReady": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.CurrentOrchestrationState",
          "StringEquals": "NamespaceCreationComplete",
          "Next": "CreateNamespaceSecrets"
        },
        {
          "Variable": "$.CurrentOrchestrationState",
          "StringEquals": "NamespaceCreationInProgress",
          "Next": "NamespaceCreationWaiter"
        },
        {
          "Variable": "$.CurrentOrchestrationState",
          "StringEquals": "NamespaceConflict",
          "Next": "Fail"
        }
      ]
    },
    "CreateNamespaceSecrets": {
      "Comment": "Create Kubernetes Secrets required by components in the namespace",
      "Type": "Task",
      "Resource": "${CREATE_NAMESPACE_SECRETS_LAMBDA_ARN}",
      "Next": "Deploy",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "MaxAttempts": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Teardown"
        }
      ]
    },
    "Deploy": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "CreateRouterService",
          "States": {
            "CreateRouterService": {
              "Comment": "Create Kubernetes Service to expose the router.",
              "Type": "Task",
              "Resource": "${CREATE_ROUTER_SERVICE_LAMBDA_ARN}",
              "End": true
            }
          }
        },
        {
          "StartAt": "DeployRouter",
          "States": {
            "DeployRouter": {
              "Comment": "Step to deploy router.",
              "Type": "Task",
              "Resource": "${DEPLOY_ROUTER_LAMBDA_ARN}",
              "End": true
            }
          }
        },
        {
          "StartAt": "DeployCalcEngine",
          "States": {
            "DeployCalcEngine": {
              "Comment": "Step to deploy calc engine.",
              "Type": "Task",
              "Resource": "${DEPLOY_CALC_ENGINE_ARN}",
              "End": true
            }
          }
        }
      ],
      "Next": "EvaluateHeartbeatStatus",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "MaxAttempts": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Teardown"
        }
      ],
      "ResultPath": null
    },
    "EvaluateHeartbeatStatus": {
      "Comment": "Step to wait for engine rediness before starting execution.",
      "Type": "Task",
      "Next": "ReadinessCheck",
      "Resource": "${EVALUATE_HEARTBEAT_STATUS_ARN}",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "MaxAttempts": 2
        }
      ],
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Teardown"
        }
      ]
    },
    "ReadinessCheck": {
      "Comment": "Readiness for router and engines.",
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.CurrentOrchestrationState",
          "StringEquals": "ReadyForTeardown",
          "Next": "Teardown"
        },
        {
          "Variable": "$.CurrentOrchestrationState",
          "StringEquals": "WaitingForEvaluation",
          "Next": "HeartbeatStatusEvaluationWaiter"
        }
      ],
      "Default": "EvaluateHeartbeatStatus"
    },
    "Teardown": {
      "Type": "Task",
      "Comment": "Teardown the created infrastructure",
      "Resource": "${TEARDOWN_ARN}",
      "Retry": [
        {
          "ErrorEquals": [
            "UnauthorizedAccessException"
          ],
          "MaxAttempts": 0
        },
        {
          "ErrorEquals": [
            "States.ALL"
          ]
        }
      ],
      "End": true
    },
    "NamespaceCreationWaiter": {
      "Type": "Wait",
      "Seconds": 10,
      "Next": "CreateNamespace"
    },
    "HeartbeatStatusEvaluationWaiter": {
      "Type": "Wait",
      "SecondsPath": "$.EvaluationStatusTimeoutSeconds",
      "Next": "EvaluateHeartbeatStatus"
    },
    "Fail": {
      "Type": "Fail"
    }
  }
}