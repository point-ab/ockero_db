"""
Utility functions for pipeline orchestration and terminal output formatting
"""
from datetime import datetime
import time


class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    END = '\033[0m'


class PipelineLogger:
    """Clean terminal output logger for pipeline execution"""
    
    def __init__(self):
        self.start_time = None
    
    def timestamp(self):
        """Get current timestamp string"""
        return datetime.now().strftime("%H:%M:%S")
    
    def print_with_timestamp(self, message, color=None):
        """Print message with timestamp"""
        timestamp = self.timestamp()
        if color:
            print(f"{timestamp}  {color}{message}{Colors.END}")
        else:
            print(f"{timestamp}  {message}")
    
    def print_header(self, title, width=40):
        """Print pipeline header"""
        print("")
        #print(f"{Colors.BOLD}{Colors.BLUE}{'=' * 70}{Colors.END}")
        print(f"{Colors.BLUE}{'=' * width} {title}{'=' * width}{Colors.END}")
        #print(f"{Colors.BOLD}{Colors.BLUE}{'=' * 70}{Colors.END}")
        print("")
        self.print_with_timestamp(f"Starting pipeline run")
    
    def print_section(self, title, width=15):
        """Print section header"""
        self.print_with_timestamp("")
        #self.print_with_timestamp("=" * 70)
        self.print_with_timestamp(f"{Colors.BOLD}{'=' * width} {title}{'=' * width} {Colors.END}") #New
        #self.print_with_timestamp("=" * 70)
        self.print_with_timestamp("")
    
    def print_step(self, step_num, total_steps, status, message, elapsed=None):
        """Print step progress in dbt style"""
        timestamp = self.timestamp()
        
        # Create the dots padding
        dots_length = max(60 - len(message), 5)
        dots = "." * dots_length
        
        if status == "START":
            print(f"{timestamp}  {step_num} of {total_steps} START {message} {dots} [RUN]")
        elif status == "OK":
            time_str = f"in {elapsed:.2f}s" if elapsed else ""
            print(f"{timestamp}  {step_num} of {total_steps} {Colors.GREEN}OK{Colors.END} {message} {dots} {Colors.GREEN}[OK {time_str}]{Colors.END}")
        elif status == "ERROR":
            time_str = f"after {elapsed:.2f}s" if elapsed else ""
            print(f"{timestamp}  {step_num} of {total_steps} {Colors.RED}ERROR{Colors.END} {message} {dots} {Colors.RED}[ERROR {time_str}]{Colors.END}")
        
        #self.print_with_timestamp("") # new



    def print_output(self, output, indent=2):
        """Print subprocess output with timestamp and indentation"""
        if output:
            for line in output.split('\n'):
                # Filter out noise (psutil warnings, empty lines)
                if line.strip() and not line.startswith('psutil'):
                    self.print_with_timestamp(f"{' ' * indent}{line.strip()}")
    
    def print_error(self, error_output):
        """Print error output in red"""
        if error_output:
            self.print_with_timestamp(f"{Colors.RED}Error details:{Colors.END}")
            for line in error_output.split('\n'):
                if line.strip():
                    self.print_with_timestamp(f"  {Colors.RED}{line.strip()}{Colors.END}")
    
    def print_success_summary(self, elapsed_time, steps):
        """Print final success summary"""
        
        self.print_with_timestamp("_" * 90) #NEW
        self.print_with_timestamp("")  # NEW
        self.print_with_timestamp(f"{Colors.GREEN}Pipeline completed successfully{Colors.END}")
        self.print_with_timestamp(f"Total execution time: {Colors.BOLD}{elapsed_time:.2f}s{Colors.END}")
        self.print_with_timestamp("")
        self.print_with_timestamp(f"{Colors.GREEN}Summary:{Colors.END}")
        
        for step in steps:
            self.print_with_timestamp(f"  ✓ {step['name']} - {Colors.GREEN}PASS{Colors.END}")
        
        self.print_with_timestamp("")
    
    def print_failure(self, step_name):
        """Print failure message"""
        self.print_with_timestamp(f"{Colors.RED}{Colors.BOLD}Pipeline failed at {step_name}{Colors.END}")
    
    def print_unexpected_error(self, error):
        """Print unexpected error"""
        self.print_with_timestamp(f"{Colors.RED}{Colors.BOLD}Unexpected error: {error}{Colors.END}")


class Timer:
    """Simple timer utility for measuring execution time"""
    
    def __init__(self):
        self.start_time = None
    
    def start(self):
        """Start the timer"""
        self.start_time = time.time()
    
    def elapsed(self):
        """Get elapsed time in seconds"""
        if self.start_time is None:
            return 0
        return time.time() - self.start_time