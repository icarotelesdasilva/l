# Here, I’m going to set up the linker from scratch for the first
# time, pulling in source code from places like OSDev and elsewhere;
# the code might be a bit rough, so I wanted to give a heads-up before
# I start coding.

ENTRY(kmain)

# The label must match the name of your kernel function so that the
# linker can find it.

SECTIONS
{

    # The physical address where the kernel will start execution.
    #
    # Stage 1 loads the stage 2 at 0x10000.
    # Stage 2 occupies 512 bytes.
    # Therefore the kernel starts at 0x10200.

    . = 0x10200;


    # The system code in text format.
    #
    # Here, we gather all the text sections so we can link them.

    .text :
    {
        *(.text)
        *(.rodata)
    }


    # This aligns the next section to a 4-byte boundary.
    #
    # ALIGN(4) means 4-byte alignment, not 4 KiB alignment.

    . = ALIGN(4);


    # Initialized Data:
    # Global variables with default values.

    .data :
    {
        *(.data)
    }


    . = ALIGN(4);


    # Uninitialized Data:
    # Here we reserve space for variables that do not have an
    # initial value.
    #
    # The .bss section does not need to contain the actual zero bytes
    # in the kernel file; the memory is expected to be zeroed at runtime.

    .bss :
    {
        *(.bss)
        *(COMMON)
    }


}
