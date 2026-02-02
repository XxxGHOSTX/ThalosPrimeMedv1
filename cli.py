#!/usr/bin/env python3
"""
Thalos Prime CLI
Command-line interface wrapper that preserves CLI functionality
"""
import argparse
import sys
from cis import CISCore


def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description="Thalos Prime - Cognitive Intelligence System CLI"
    )
    
    parser.add_argument(
        "intent",
        nargs="*",
        help="Task intent to execute"
    )
    
    parser.add_argument(
        "--status",
        action="store_true",
        help="Show CIS status"
    )
    
    parser.add_argument(
        "--interactive",
        "-i",
        action="store_true",
        help="Enter interactive mode"
    )
    
    args = parser.parse_args()
    
    # Initialize CIS Core
    cis = CISCore()
    
    if args.status:
        # Show status
        status = cis.get_status()
        print("\n=== Thalos Prime Status ===")
        print(f"Initialized: {status['initialized_at']}")
        print(f"Total Tasks: {status['total_tasks']}")
        print("\nStatus Breakdown:")
        for status_name, count in status['status_breakdown'].items():
            print(f"  {status_name}: {count}")
        return 0
    
    elif args.interactive:
        # Interactive mode
        print("=== Thalos Prime Interactive Mode ===")
        print("Enter tasks/intents (type 'exit' to quit)\n")
        
        while True:
            try:
                intent = input("Intent> ").strip()
                
                if not intent:
                    continue
                
                if intent.lower() in ["exit", "quit", "q"]:
                    print("Goodbye!")
                    break
                
                # Submit and execute task
                task = cis.submit_task(intent)
                print(f"\nTask ID: {task.id}")
                print("Executing...")
                
                task = cis.execute_task(task.id)
                
                if task.status.value == "completed":
                    print(f"\n✓ Completed")
                    print(f"Result: {task.result}\n")
                else:
                    print(f"\n✗ Failed")
                    print(f"Error: {task.error}\n")
                    
            except KeyboardInterrupt:
                print("\nInterrupted. Goodbye!")
                break
            except EOFError:
                print("\nGoodbye!")
                break
        
        return 0
    
    elif args.intent:
        # Single task execution
        intent = " ".join(args.intent)
        
        print(f"Submitting task: {intent}")
        
        # Submit and execute task
        task = cis.submit_task(intent)
        print(f"Task ID: {task.id}")
        print("Executing...")
        
        task = cis.execute_task(task.id)
        
        if task.status.value == "completed":
            print(f"\n✓ Task completed successfully")
            print(f"Result: {task.result}")
            return 0
        else:
            print(f"\n✗ Task failed")
            print(f"Error: {task.error}")
            return 1
    
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
