# Trigger a build of the deployed image pipeline and wait for it to complete building
# If the build fails or is manually cancelled by the user through the imageBuilder UI,
# this workflow will successfully exit

# trigger an execution
triggered_image_build=$(aws imagebuilder start-image-pipeline-execution --image-pipeline-arn "$IMAGE_PIPELINE_ARN")
echo "triggered image build"
echo "$triggered_image_build"

# triggered_image_build is a json with a key called imageBuildVersionArn. Extract the value of this key and store it in a variable
image_build_version_arn=$(echo "$triggered_image_build" | jq -r .imageBuildVersionArn)
echo "image build version arn"
echo "$image_build_version_arn"

# wait for the image to build
build_status="$(aws imagebuilder get-image --image-build-version-arn "$image_build_version_arn" --query "image.state.status" --output text)"
running_duration=0
token_duration=1200  # seconds
while [[ $build_status != "AVAILABLE" ]]; do
  # echo the build status
  echo "image is in state $build_status"

  # get the build status
  build_status="$(aws imagebuilder get-image --image-build-version-arn "$image_build_version_arn" --query "image.state.status" --output text)"

  # terminate if the build fails or if the build status is Cancelled
   if [[ $build_status == "CANCELLED" ||  $build_status == "FAILED" ]]; then
     echo "Build status is $build_status"
     echo "Cancelling workflow"
     break;
   fi

  # wait for 10 seconds
  sleep 10

  # add 10 seconds to running_duration
  running_duration=$((running_duration + 10))

  token_duration=$((token_duration - 10))

  # refresh the session token if needed
  if [[ token_duration -lt 0 ]]; then
    echo "refreshing session token"
    # clear the cache where the session info is stored. This automatically creates a new session
    rm -r ~/.aws/cli/cache
    token_duration=1200
  fi

  # if running_duration is longer than the $TIMEOUT_SECONDS, then cancel the imagebuilder image build
  if [[ $running_duration -gt $TIMEOUT_AFTER ]]; then
    echo "Timeout of $TIMEOUT_AFTER seconds has been reached, cancelling image build"
    aws imagebuilder cancel-image-creation --image-build-version-arn "$image_build_version_arn"
    break;
  fi
done