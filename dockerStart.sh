#!/bin/bash

log() {
    echo "$1"
    echo "$1" >>"$LOG_FOLDER/main.log"
}

keep_logs() {
    log "Copying logs for $1."
    cp -f $(docker inspect -f {{.LogPath}} $1) "$LOG_FOLDER/$DATE_WITH_TIME/$1.log" 2>/dev/null || :
}

symlink_logs() {
    log "Symlinking logs for $1."
    chown demo:demo $(docker inspect -f {{.LogPath}} $1)
    ln -sfn $(docker inspect -f {{.LogPath}} $1) "$LOG_FOLDER/$1.log"
}

check_docker_health() {
    log "Checking health of $1."
    if [ "$(docker container inspect -f '{{.State.Status}}' $1)" == "running" ]; then
        log "$1 is running."
    else
        log "$1 is NOT running."
    fi
}

pull_dockers() {
    if [ -z "$AWS_PROFILE" ]; then
        log "Loging to AWS docker."
        aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 993298895423.dkr.ecr.us-east-1.amazonaws.com
    else
        log "Loging to AWS docker using profile $AWS_PROFILE."
        aws --profile $AWS_PROFILE ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 993298895423.dkr.ecr.us-east-1.amazonaws.com
    fi

    log "Using docker-compose file: '$DOCKER_COMPOSE_FILE'"
    log "Pulling REDIS."
    docker-compose --log-level CRITICAL -f $DOCKER_COMPOSE_FILE pull redis
    log "Pulling REDIS DONE."
    log "Pulling MONGO."
    docker-compose --log-level CRITICAL -f $DOCKER_COMPOSE_FILE pull mongo
    log "Pulling MONGO DONE."
    log "Pulling demo-webserver."
    docker-compose --log-level CRITICAL -f $DOCKER_COMPOSE_FILE pull demo-webserver
    log "Pulling demo-webserver DONE."
    log "Pulling demo-backend."
    docker-compose --log-level CRITICAL -f $DOCKER_COMPOSE_FILE pull demo-backend
    log "Pulling demo-backend DONE."
    log "Pulling demo-camera-controller."
    docker-compose --log-level CRITICAL -f $DOCKER_COMPOSE_FILE pull demo-camera-controller
    log "Pulling demo-camera-controller DONE."
    log "Pulling demo-identification-worker."
    docker-compose --log-level CRITICAL -f $DOCKER_COMPOSE_FILE pull demo-identification-worker
    log "Pulling demo-identification-worker DONE."
    log "Pulling demo-authenticity-worker."
    docker-compose --log-level CRITICAL -f $DOCKER_COMPOSE_FILE pull demo-authenticity-worker
    log "Pulling demo-authenticity-worker DONE."
    log "Pulling dockers DONE."

}

while getopts c:l:p:d:a:e: option; do
    case "${option}" in

    c) CONFIG=${OPTARG} ;;
    l) LOG_FOLDER=${OPTARG} ;;
    a) AWS_PROFILE=${OPTARG} ;;
    d) DOCKER_COMPOSE_FILE=${OPTARG} ;;
    e) ENV_FILE=${OPTARG} ;;
    esac
done

if [ -z "$LOG_FOLDER" ]; then
    echo "You must specify LOG_FOLDER parameter using like '-l /home/demo/Deskotp/log'"
    exit 1
fi

mkdir -p $LOG_FOLDER
if id "demo" &>/dev/null; then
    log "Changing ownership of the log folder"
    chown -R demo:demo $LOG_FOLDER
else
    log 'user demo was not found'
fi

if [ -z "$CONFIG" ]; then
    log "You must specify CONFIG parameter using like '-c /home/demo/Deskotp/config.ini'"
    exit 1
fi

if [ -z "$ENV_FILE" ]; then
    log "You must specify ENV_FILE parameter using like '-e /app/orchestrator/.env'"
    exit 1
fi

if [ -z "$DOCKER_COMPOSE_FILE" ]; then
    log "You must specify DOCKER_COMPOSE_FILE parameter using like '-d /app/orchestrator/docker-compose.yml'"
    exit 1
fi

set -a
. $CONFIG
set +a

if [ -z "$PULL" ]; then
    log "You are missing 'PULL' variable in the config file. Add 'PULL=true' to $PULL"
    exit 1
fi

if [ $PULL = "true" ]; then
    log "Dockers automatic pulling is enabled. Will attempt to pull dockers."
    pull_dockers
else
    log "Dockers automatic pulling is disable. Dockers will be starting now."
fi

if id "demo" &>/dev/null; then
    DATE_WITH_TIME=$(date "+%Y%m%d-%H%M%S")
    mkdir -p $LOG_FOLDER/$DATE_WITH_TIME
    keep_logs "redis"
    keep_logs "mongo"
    keep_logs "demo-webserver"
    keep_logs "demo-backend"
    keep_logs "demo-camera-controller"
    keep_logs "demo-identification-worker"
    keep_logs "demo-authenticity-worker"
    chown -R demo:demo $LOG_FOLDER
else
    log 'user demo was not found'
fi

docker-compose -p veracity-demo --env-file=${ENV_FILE} --log-level CRITICAL -f $DOCKER_COMPOSE_FILE down
docker-compose -p veracity-demo --env-file=${ENV_FILE} --log-level CRITICAL -f $DOCKER_COMPOSE_FILE up -d --force-recreate
log "Dockers were started."

check_docker_health "redis"
check_docker_health "mongo"
check_docker_health "demo-webserver"
check_docker_health "demo-backend"
check_docker_health "demo-camera-controller"
check_docker_health "demo-identification-worker"
check_docker_health "demo-authenticity-worker"

if id "demo" &>/dev/null; then
    symlink_logs "redis"
    symlink_logs "mongo"
    symlink_logs "demo-webserver"
    symlink_logs "demo-backend"
    symlink_logs "demo-camera-controller"
    symlink_logs "demo-identification-worker"
    symlink_logs "demo-authenticity-worker"
    chown -R demo:demo $LOG_FOLDER
else
    log 'user demo was not found'
fi
