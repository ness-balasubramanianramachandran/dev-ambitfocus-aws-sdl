resource "aws_cloudwatch_dashboard" "ec2_dashboard" {
  dashboard_name = "Overall-Dashboard"
  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/EC2","CPUUtilization","InstanceId","${aws_instance.mssql_server.id}"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "EC2 CPU - MSSQL Server",
        "liveData": false,
        "legend": {
          "position": "bottom"
        }
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/EC2","CPUUtilization","InstanceId","${aws_instance.application_server[0].id}"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "EC2 CPU - Application Server",
        "liveData": false,
        "legend": {
          "position": "bottom"
        }
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 6,
      "height": 6,
      "properties": {
        "view": "timeSeries",
        "title": "Memory % - MSSQL Server",
        "stacked": true,
        "metrics": [
          ["CWAgent","Memory % Committed Bytes In Use","InstanceId","${aws_instance.mssql_server.id}"]
        ],
        "region": "us-east-1",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 6,
      "width": 6,
      "height": 6,
      "properties": {
        "view": "timeSeries",
        "title": "Memory % - Application Server",
        "stacked": true,
        "metrics": [
          ["CWAgent","Memory % Committed Bytes In Use","InstanceId","${aws_instance.application_server[0].id}"]
        ],
        "region": "us-east-1",
        "period": 300
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 12,
      "width": 6,
      "height": 6,
      "properties": {
        "view": "gauge",
        "title": "Available Disk % - MSSQL Server",
        "metrics": [
          ["CWAgent","LogicalDisk % Free Space","InstanceId","${aws_instance.mssql_server.id}"]
        ],
          "region": "us-east-1",
          "yAxis": {
            "left": {
              "min": 0,
              "max": 100
            }
          },
          "stacked": false,
          "period": 300
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 12,
      "width": 6,
      "height": 6,
      "properties": {
        "view": "gauge",
        "title": "Available Disk % - Application Server",
        "metrics": [
          ["CWAgent","LogicalDisk % Free Space","InstanceId","${aws_instance.application_server[0].id}"]
        ],
          "region": "us-east-1",
          "yAxis": {
            "left": {
              "min": 0,
              "max": 100
            }
          },
          "stacked": false,
          "period": 300
      }
    },
    {
    "height": 6,
    "width": 12,
      "x": 12,
      "y": 18,
      "type": "metric",
      "properties": {
        "sparkline": true,
        "view": "timeSeries",
        "stacked": false,
        "metrics": [
          [ "AWS/EC2", "CPUUtilization", { "period": 300, "stat": "Average" } ],
          [ ".", "DiskReadBytes" ],
          [ ".", "DiskReadOps" ],
          [ ".", "DiskWriteBytes" ],
          [ ".", "DiskWriteOps" ],
          [ ".", "NetworkIn" ],
          [ ".", "NetworkOut" ]
        ],
        "legend": {
          "position": "right"
        },
        "region": "us-east-1",
        "liveData": false,
        "title": "EC2-Overall-Data",
        "start": "-PT1H",
        "end": "P0D"
      }
    }
  ]
}
EOF
}