.. _METADATA:

Marmalade NG Metadata
=====================

General considerations
----------------------

Metadata can be attached using externals URI:

* to tokens through the ledger: **Mandatory** (retrieved by :ref:`LEDGER-GET-URI`)
* to collections through the collection policy : **Optional** (retrieved by :ref:`POLICY-COLLECTION_GET-COLLECTION`)

URIs must point to a JSON off-chain Metadata Object.

It is highly recommended to only store metadata (and NFTs related content like images) in reliable, immutable and long term storage.
As such URI starting with ``https://`` or ``http://`` must be avoided. And Marketplaces should tag these NFTs as unsafe.

The 2 available options for NFT storage are either:

* IPFS (``ipfs://CID``), with a sufficient number of pinning servers (Filecoin may help)

* KDAFS (``kdafs://network:chain/namespace.module/CID``) (as per Draft KIP 25: https://github.com/kadena-io/KIPs/blob/75099f2e112c87ad4669f1a643cbd7bf49cfce66/kip-0025.md)


**In case of IPFS, the URI must not include an `https` gateway.**: Only the raw CID prefixed by ``ipfs://`` must be present.

Note that the reference implementation of Marmalade NG: (https://explorer.marmalade-ng.xyz) supports in native ipfs and kdafs.

Token metadata
--------------

Specification
~~~~~~~~~~~~~

A token metadata has the following format:

.. list-table:: JSON Metadata
  :widths: 25 15 60
  :header-rows: 1

  * - Field Name
    - Data Type
    - Description

  * - name
    - string
    - Identifies the asset to which this NFT represents.

  * - description
    - string
    - Describes the asset to which this NFT represents.

  * - image
    - string
    - | A URI pointing to a resource with mime type ``image/*`` representing the asset
      | to which this NFT represents. Consider making any images at a width between
      | 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive.
      | The string may be a an embedded image in dataURI format as per RFC 2397.

  * - | attributes
      | *(Optional)*
    - array of objects
    - | An array of objects, each representing a characteristic or trait of the
      | NFT, with a *trait_type* field specifying the trait's name and a *value*
      | field specifying the trait's value.

  * - | properties
      | *(Optional, see below)*
    - object
    - Arbitrary properties. Values may be strings, numbers, object or arrays.


.. list-table:: JSON Metadata (properties object)
  :widths: 25 15 60
  :header-rows: 1

  * - Field Name
    - Data Type
    - Description

  * - | authors
      | *(Optional)*
    - array of objects
    - | An array of authors who created or contributed to the asset. Each author
      | is an object with a *name* field specifying the author's name.

  * - | external_url
      | *(Optional)*
    - string
    - URL to an external application or website where users can also view the asset.

  * - | animation_url
      | *(Optional)*
    - string
    - | URL to a multimedia attachment of the asset. The supported file formats are
      | MP4 and MOV for video, MP3, FLAC and WAV for audio, GLB for AR/3D assets,
      | and HTML for HTML pages. You may use the ``?ext={file_extension}`` query to
      | provide information on the file type.

  * - | collection
      | *(Optional)*
    - object
    - | An object with a *name* field specifying the name of the collection, and a
      | *family* field specifying the larger category or group to which the collection belongs.


JSON Schema
~~~~~~~~~~~

.. literalinclude:: ../../metadata/meta-schema-v1.json
   :language: json

Example
~~~~~~~

.. literalinclude:: ../../examples/metadata/meta_example.json
   :language: json



.. _METADATA_COLLECTIONS:

Collection metadata
-------------------
Specification
~~~~~~~~~~~~~

.. list-table:: JSON Metadata
  :widths: 25 15 60
  :header-rows: 1

  * - Field Name
    - Data Type
    - Description

  * - name
    - string
    - The name of the collection.

  * - description
    - string
    - The description of the collection.

  * - image
    - string
    - | A URI pointing to a resource with mime type image/* that represents the collection,
      | typically displayed as a profile picture for the collection.

  * - banner_image
    - string
    - | A URI pointing to a resource with mime type image/* that represents the collection,
      | displayed as a banner image for the collection.

  * - featured_image
    - string
    - | A URI pointing to a resource with mime type image/* that represents the collection,
      | typically used for a highlight section.

  * - external_link
    - string
    - The external link of the collection.

  * - | properties
      | *(Optional, see below)*
    - object
    - Arbitrary properties. Values may be strings, numbers, object or arrays.



.. list-table:: JSON Metadata (properties object)
  :widths: 25 15 60
  :header-rows: 1

  * - Field Name
    - Data Type
    - Description

  * - | authors
      | *(Optional)*
    - array of objects
    - | An array of authors who created or contributed to the asset. Each author
      | is an object with a *name* field specifying the author's name.

  * - | Other optional fields
      | *(Optional)*
    - Depends
    - Any fields can be added here as required by the collection author.


JSON Schema
~~~~~~~~~~~
.. literalinclude:: ../../metadata/collection-meta-schema-v1.json
   :language: json


Example
~~~~~~~
