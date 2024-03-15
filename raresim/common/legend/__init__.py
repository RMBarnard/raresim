__all__ = ["Legend", "LegendReaderWriter"]

from inspect import isclass
from pkgutil import iter_modules
from importlib import import_module
import os

# iterate through the modules in the current package
package_dir = os.path.join(os.path.abspath(__file__), os.pardir)
for (_, module_name, _) in iter_modules([package_dir]):

    # import the module and iterate through its attributes
    module = import_module(f"{__name__}.{module_name}")
    for attribute_name in dir(module):
        attribute = getattr(module, attribute_name)

        if isclass(attribute):
            # Add the class to this package's variables
            globals()[attribute_name] = attribute