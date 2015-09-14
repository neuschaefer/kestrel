#ifndef MAX_DEVS
#error "MAX_DEVS must be defined for this header; include config.h ahead of me."
#endif

#ifndef E_ADDRESS_SPACE_H
#define E_ADDRESS_SPACE_H


typedef struct AddressSpace	AddressSpace;

typedef void (*WRFUNC)(AddressSpace *, UDWORD, UDWORD, int);
typedef UDWORD (*RDFUNC)(AddressSpace *, UDWORD, int);

struct AddressSpace {
	UBYTE	*rom;
	UBYTE	*ram;
	WRFUNC	writers[MAX_DEVS];
	RDFUNC	readers[MAX_DEVS];
};


struct interface_AddressSpace {
	AddressSpace *(*make)(Options *opts);

	void (*store_byte)(AddressSpace *as, DWORD address, BYTE datum);
	void (*store_hword)(AddressSpace *as, DWORD address, UHWORD datum);
	void (*store_word)(AddressSpace *as, DWORD address, UWORD datum);
	void (*store_dword)(AddressSpace *as, DWORD address, UDWORD datum);
	BYTE (*fetch_byte)(AddressSpace *as, DWORD address);
	HWORD (*fetch_hword)(AddressSpace *as, DWORD address);
	WORD (*fetch_word)(AddressSpace *as, DWORD address);
	DWORD (*fetch_dword)(AddressSpace *as, DWORD address);
};

extern const struct interface_AddressSpace module_AddressSpace;

#endif
