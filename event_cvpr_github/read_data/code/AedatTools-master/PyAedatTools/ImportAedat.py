# -*- coding: utf-8 -*-

"""
ImportAedat

Code contributions from Bodo Rueckhauser
"""

from PyAedatTools.ImportAedatHeaders import ImportAedatHeaders
from PyAedatTools.ImportAedatDataVersion1or2 import ImportAedatDataVersion1or2
from PyAedatTools.ImportAedatDataVersion3 import ImportAedatDataVersion3

def ImportAedat(aedat):
    """
    Parameters
    ----------
    args :

    Returns
    -------
    """

# To handle: missing args; search for file to open - request to user

    with open(aedat['importParams']['filePath'], 'rb') as aedat['importParams']['fileHandle']:
        aedat = ImportAedatHeaders(aedat)
        if aedat['info']['fileFormat'] < 3:
            return ImportAedatDataVersion1or2(aedat)
        else:
            return ImportAedatDataVersion3(aedat)
 