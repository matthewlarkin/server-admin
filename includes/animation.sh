# Define the animation
animation() {
    local emojis=('🌍' '🌎' '🌏')
    while true; do
        for i in "${emojis[@]}"; do
            printf "\r$i"
            sleep 0.2
        done
    done
}

# Function to run a series of commands with animation
run_with_animation() {
    local commands=$1
    local success_message=$2

    animation & # Start the animation
    local ANIMATION_PID=$!
    echo "$commands" | xargs -I {} sh -c "{}" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        kill $ANIMATION_PID # Stop the animation
        printf "\r${red}Failed to run commands.${reset}\n"
        exit 1
    else
        kill $ANIMATION_PID # Stop the animation
        printf "\r${green}$success_message${reset}\n"
    fi
}