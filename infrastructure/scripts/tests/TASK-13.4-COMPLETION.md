# Task 13.4 Completion: Implement Service Restart for Update Mode

## Task Description
Implement the `restart_services()` function in `infrastructure/scripts/deploy.sh` to handle service restart in update mode.

## Requirements
- Check if running in update mode (MODE variable should be "update")
- Restart the ai-website-builder service using systemctl restart
- Verify service restarted successfully
- Display progress messages and log all operations
- Handle errors gracefully with descriptive messages

## Implementation Summary

### Function Location
- **File**: `infrastructure/scripts/deploy.sh`
- **Function**: `restart_services()`
- **Lines**: Approximately 2196-2250

### Key Features Implemented

#### 1. Mode Verification
```bash
if [ "$MODE" != "update" ]; then
    display_warning "restart_services called but not in update mode (MODE=$MODE)"
    log_operation "WARNING: restart_services called in $MODE mode, expected update mode"
    return 0
fi
```
- Checks that the function is called in update mode
- Logs a warning if called in the wrong mode
- Returns gracefully without error

#### 2. Service Restart
```bash
if systemctl restart ai-website-builder >> "$LOG_FILE" 2>&1; then
    display_success "Service restarted successfully"
    log_operation "systemctl restart ai-website-builder completed successfully"
```
- Uses `systemctl restart ai-website-builder` to restart the service
- Redirects output to log file for troubleshooting
- Displays success message on successful restart

#### 3. Progress Messages
- `display_progress "Restarting services after configuration update..."`
- `display_info "Applying configuration changes by restarting ai-website-builder service"`
- `display_progress "Restarting ai-website-builder service..."`
- `display_success "Service restarted successfully"`
- `display_success "Service restart completed successfully"`

#### 4. Logging
- Logs function entry: `log_operation "FUNCTION: restart_services called"`
- Logs mode check warnings if applicable
- Logs restart operation: `log_operation "Running systemctl restart ai-website-builder"`
- Logs success: `log_operation "systemctl restart ai-website-builder completed successfully"`
- Logs errors: `log_operation "ERROR: systemctl restart ai-website-builder failed"`

#### 5. Error Handling
Comprehensive error handling includes:
- Formatted error message with visual separators
- Display of service logs (last 20 lines) using `journalctl`
- Detailed remediation steps:
  1. Check the log file for details
  2. View full service logs
  3. Check service status
  4. Verify configuration file is valid
  5. Try restarting manually
  6. Check application logs
- Exit with error code 1 on failure

### Integration
The function is called in the main deployment flow:
```bash
if [ "$MODE" = "update" ]; then
    restart_services
else
    start_services
fi
```

This ensures that:
- In fresh installation mode, services are started for the first time
- In update mode, services are restarted to apply configuration changes

## Validation

### Manual Code Review Checks
✅ Function checks MODE variable for "update"  
✅ Function uses `systemctl restart ai-website-builder`  
✅ Function logs all operations  
✅ Function displays progress messages  
✅ Function handles errors with if/else  
✅ Function provides remediation guidance  
✅ Function displays service logs on error using journalctl  
✅ Function verifies and reports restart success  
✅ Function is fully implemented (no TODO/placeholder)  

### Requirements Validation
✅ **Requirement 5.6**: "WHEN configuration updates complete, THE Deployment_Script SHALL restart affected services"
- The function is called after configuration updates in update mode
- It restarts the ai-website-builder service
- It verifies the restart was successful

## Testing
A test script was created at `infrastructure/scripts/tests/test-task-13.4-restart-services.sh` that validates:
1. Function exists in deploy.sh
2. Function checks MODE variable
3. Function uses systemctl restart
4. Function logs operations
5. Function displays progress messages
6. Function handles errors
7. Function provides remediation guidance
8. Function displays service logs on error
9. Function verifies restart success
10. Function is not a placeholder

## Files Modified
- `infrastructure/scripts/deploy.sh` - Implemented `restart_services()` function

## Files Created
- `infrastructure/scripts/tests/test-task-13.4-restart-services.sh` - Test script for validation
- `infrastructure/scripts/tests/TASK-13.4-COMPLETION.md` - This completion document

## Status
✅ **COMPLETE** - All requirements implemented and validated

## Next Steps
Task 13.5 will implement unit tests for service management, including testing the restart_services function in a more comprehensive test suite.
