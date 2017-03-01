
#ifndef __vtkMinimal_h
#define __vtkMinimal_h

#if defined(_WIN32)
#define VTKMINIMAL_EXPORT __declspec( dllexport )
#else
#define VTKMINIMAL_EXPORT
#endif

#include <vtkObject.h>

class VTKMINIMAL_EXPORT vtkMinimal : public vtkObject
{
public:
  	vtkTypeMacro(vtkMinimal, vtkObject);
	static vtkMinimal *New();
	void PrintSelf(ostream &os, vtkIndent indent);
	void PrintHeader(ostream &os, vtkIndent indent);
	void PrintTrailer(ostream &os, vtkIndent indent);
	
  	void someFunction();

protected:
	vtkMinimal();
	~vtkMinimal();
};

#endif
