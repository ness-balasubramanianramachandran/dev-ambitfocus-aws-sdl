resource "aws_lambda_layer_version" "fis_cacert" {
  filename                 = data.archive_file.fis_cacert.output_path
  description              = "Lambda layer containing FIS internal CA cert"
  layer_name               = "fis_cacert"
  compatible_runtimes      = ["dotnet6"]
  compatible_architectures = ["x86_64", "arm64"]
  source_code_hash         = data.archive_file.fis_cacert.output_base64sha256
}