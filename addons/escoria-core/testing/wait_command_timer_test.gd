extends GdUnitTestSuite

var _result := -1


## Verify a completed wait frees its timer and tolerates later interruption.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_completed_wait_releases_timer() -> void:
    var command := WaitCommand.new()
    _result = -1
    _run_wait(command, 0.01)
    var timer := command.timer
    await timer.timeout
    await get_tree().process_frame
    assert_int(_result).is_equal(ESCExecution.RC_OK)
    assert_bool(is_instance_valid(timer)).is_false()
    command.interrupt()
    if is_instance_valid(timer):
        timer.free()


## Verify interrupting a pending wait frees its timer and is safe to repeat.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func test_interrupted_wait_releases_timer() -> void:
    var command := WaitCommand.new()
    _result = -1
    _run_wait(command, 60.0)
    var timer := command.timer
    command.interrupt()
    command.interrupt()
    await get_tree().process_frame
    assert_int(_result).is_equal(ESCExecution.RC_OK)
    assert_bool(is_instance_valid(timer)).is_false()
    command.interrupt()
    if is_instance_valid(timer):
        timer.free()


func _run_wait(command: WaitCommand, seconds: float) -> void:
    _result = await command.run([seconds])
