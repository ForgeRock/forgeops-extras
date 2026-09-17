# docker-bake.hcl

# Build configuration variables
variable "REGISTRY" {
  default = "us-docker.pkg.dev"
}

variable "REPOSITORY" {
  default = "forgeops-public/images"
}

variable "CACHE_REGISTRY" {
  default = REGISTRY
}

variable "CACHE_REPOSITORY" {
  default = REPOSITORY
}

variable "NO_CACHE" {
  default = false
}

variable "PULL" {
  default = true
}

variable "BUILD_ARCH" {
  default = "amd64,arm64"
}

variable "VERSION" {
}

variable "PLATFORM_RELEASE" {
  default = ""
}

# This allows you to make this a timestamped string
# VERSION=8.1.1 BUILD_TAG=8.1.1-$(date +YYYYMMddhhmm) docker buildx bake ...
variable "BUILD_TAG" {
  default = "${VERSION}"
}

variable "BUILD_TAGS" {
  default = "${BUILD_TAG},${VERSION}-latest,latest"
}

variable "FROM_TAG" {
  default = "1.31.5-alpine"
}

# Helper functions
function "platforms" {
  params = [BUILD_ARCH]
  result = "${formatlist("linux/%s", "${split(",", "${BUILD_ARCH}")}")}"
}

function "tags" {
  params = [REGISTRY, REPOSITORY, image, BUILD_TAGS]
  result = "${formatlist("${REGISTRY}/${REPOSITORY}/${image}:%s", "${split(",", "${BUILD_TAGS}")}")}"
}

# Build targets
group "default" {
  targets = [
    "idm-admin-ui",
  ]
}

target "idm-admin-ui" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = "${platforms("${BUILD_ARCH}")}"
  no-cache = NO_CACHE
  pull = PULL
  args = {
    TAG = FROM_TAG
    VERSION = VERSION
  }
  tags = "${tags("${REGISTRY}", "${REPOSITORY}", "idm-admin-ui", "${BUILD_TAGS}")}"
  output = ["type=registry"]
  cache-to = ["mode=max,type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/idm-admin-ui:build-cache"]
  cache-from = ["type=registry,ref=${CACHE_REGISTRY}/${CACHE_REPOSITORY}/idm-admin-ui:build-cache"]
}
