## Glossaire

Certificat : Identifiant numérique d'une machine/d'un service. Le certificat est publique mais ne peut être exploité qu'à la condition d'être en possession d'une clé privée/secrète associée.

PKI : Public-key infrastructure/[Infrastructure à clés publiques](https://fr.wikipedia.org/wiki/Infrastructure_%C3%A0_cl%C3%A9s_publiques)

CA : Certificate Authority/[Autorité de certification](https://fr.wikipedia.org/wiki/Autorit%C3%A9_de_certification)

CSR/Certificate Signing Request : Certificat proposé à la signature par une CA.

Cryptosystème à seuil : [https://fr.wikipedia.org/wiki/Cryptosyst%C3%A8me_%C3%A0_seuil](https://fr.wikipedia.org/wiki/Cryptosyst%C3%A8me_%C3%A0_seuil)

SSS : [Shamir Secret Sharing](https://fr.wikipedia.org/wiki/Partage_de_cl%C3%A9_secr%C3%A8te_de_Shamir)

Offline : hors-ligne, non connecté au réseau.

Online : en-ligne (accessible depuis l'Internet)

GPG/GnuPG : GNU Privacy Guard. Équivalent ouvert de l'outil PGP. Ce logiciel permet la signature et le chiffrement de messages et de fichiers, garantissant ainsi leur authenticité, leur intégrité et/ou leur confidentialité.

Signature numérique/signature cryptographique : Signature cryptographiquement vérifiable d'un document numérique à l'aide de l'outil GPG. La vérification de cette signature requiert l'utilisation de la clé publique du signataire, et utilise ainsi la fonctionnalité d'authenticité et d'intégralité de GPG.

GPG keyring/trousseau de clés GPG : Base de donnée GPG contentant l'ensemble des clés connues par GPG, leur éventuels secrets rattachés, et le niveau de confiance accordé à chaque clé.

Checksum : Somme de contrôle. Dans cette documentation, on utilise de façon extensive des hachages cryptographiquement sécurisés (non falsifiables), qui seront appelés "checksums sha256" par abus de langage. L'avantage apporté par une fonction de hachage par rapport à simple une somme de contrôle est qu'il n'est pas possible de manipuler les données d'entrées en visant par avance un résultat numérique arbitraire.

Hardware Token : un équipement électronique permettant d'enfouir des secrets (par exemple des clés privées GPG) dans un produit physique plutôt que dans un fichier sur un disque dur.

Yubikey : Hardware token accessible à un prix abordable, s'interfaçant nativement avec GPG en le branchant sur un port USB.

Vault/Hashicorp Vault : Service logiciel combinant un grand nombre de fonctionalités de manipulations de secrets, et de primitive cryptographiques (comme l'automatisation d'une CA).

Vault Private Data : Contenu de la base de données (état au repos) d'un Vault Hashicorp. Ce sont ces données qui constituent l'état du Vault, et qui doivent donc être sauvegardée pour assurer la pérénité du Vault et de la PKI qu'il contient.

Unseal share : Portion d'un secret permettant de déverouiller la base de données d'un Vault Hashicorp. Plusieurs "shares" doivent être réunies pour pouvoir dévérouiller totalement un Vault.

Unseal/Dévérouiller un Vault Hashicorp : Un Vault vérouillé n'est pas utilisable, ses données sont chiffrées et inexploitables en l'état. L'action de dévérouiller nécessite un quorum minimum de personnes disposant d'une "unseal share" (quorum assuré à l'aide de la technologie de cryptosystème à seuil "SSS").

Seal/Vérouiller un Vault Hashicorp : Un Vault dévérouillé peut être vérouillé par toute personne ayant une autorisation valide sur le Vault.

Token : Jeton d'accès à un Vault Hashicorp, généré suite à la preuve de son identité (via un login ou un certificat par exemple).

Root token : Jeton d'accès disposant de l'intégralité des droits sur un Vault Hashicorp.

Ephemeral Vault/Vault éphémère : Service Hashicorp Vault temporaire lancé sur une base de données existante ou non. La machine et le logiciel Hashicorp Vault sont dans ce cas là complètement temporaires, voire jetables. Seule la base de donnée Vault Private Data du Vault contient l'état du Vault (en entrée avant le démarrage du Vault éphémère, et en sortie après l'arrête du Vault éphémère).

Cérémonie : Évènement durant lequel est effectuée une session de travail sur la PKI. Cette session est officialisée, planifiée, et donne lieu à un rapport auditable.

Rapport de cérémonie : Document auditable, signé numériquement, retraçant le contexte, l'ensemble des participants, et des actions effectuées durant une cérémonie.

Trusted commit : État arrêté d'un dépôt git (commit), pour lequel le contenu du dépôt a été audité comme étant de confiance.

ISO/ISO9660 : format de système de fichier en lecture seule pour les disques optiques (étendu aux clés USB bootables). Dans le cadre du Vault éphémère, ce système de fichier contient l'intégralité du système d'exploitation, qui est donc figé et autosuffisant.

Bootable live media : Support de masse programmé avec une image ISO9660.

Vault writable partition : partition secondaire sur le media bootable du Vault éphémère. Cette partition, à la différence de la partition ISO, contient les données modifiables du Vault (par exemple, la partie Vault Private Data, les fichiers de journal, les certificats générés etc.)
