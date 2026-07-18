# Quill.AI — Point d'étape pour le prof

## Où j'en suis

**v1 — ce que je soutiens (fonctionnel, testé) :**
Tasks, Calendar, Pomodoro, Habits, Notebook (éditeur par blocs), Flashcards (Leitner 5 boîtes), Mystro (chat + génération de cartes) — tout en local sur l'appareil, zéro backend. Mystro tourne sur l'API Gemini (gratuite), pas Claude — à corriger si ça apparaît encore comme "API Claude" dans mes schémas.

**v2 — Classroom / Groupes, statut réel : conçu, pas commencé côté backend.**
Une v1 locale de Classroom existe déjà (créer/rejoindre un groupe, diffuser une tâche, rôle prof/élève) mais elle ne marche que sur un seul appareil — un code d'invitation créé sur mon téléphone n'est pas trouvable depuis un autre. J'ai la spec complète de la vraie v2 (3 onglets : Tâches / Membres / Progression, règle "zéro chat dans le groupe"), mais la construire pour de vrai demande un backend (Supabase) que je n'ai pas encore mis en place.

## Ce qui bloque, concrètement

Pour que "rejoindre un groupe" marche entre deux téléphones différents, il faut :
1. Un projet Supabase réel (base de données + authentification).
2. De vrais comptes utilisateurs (aujourd'hui la connexion est un mock local, pas une vraie authentification).
3. Que Tasks et Focus Sessions se synchronisent aussi — sinon les streaks et "sessions cette semaine" dans l'onglet Membres n'ont pas de vraies données à afficher.

Autrement dit : Classroom v2 n'est pas juste "ajouter des tables" — ça touche l'architecture de toute l'app (passer du 100% local à un vrai client-serveur).

## Décisions à valider avec lui

- **Est-ce que la vraie migration Supabase (v2) est dans le scope de la soutenance, ou est-ce que je la garde comme "perspective" (comme Notebook/Flashcards l'étaient avant de les construire) ?**
- **Si oui : le temps restant permet-il une vraie authentification + sync complet (Tasks + Sessions + Classroom), ou seulement Classroom seul (streaks/progression restent alors non disponibles) ?**
- Rappel du tri MVP déjà fait : indispensable v2 = créer/rejoindre par code, liste, diffusion + copie, onglet membres avec streaks, quitter/retirer. Reportable v3 = lien URL, partage WhatsApp, notifications push, progression détaillée par étudiant, insight Mystro.

## Phrase de synthèse (déjà validée, réutilisable telle quelle)

> « Quill.AI aura deux boucles : la boucle d'exécution — plan, focus, écart — déjà réalisée, et la boucle du savoir — note, carte, mémoire — en perspective. Mystro est le point où les deux se rejoignent. »

Et pour Classroom : « Les groupes servent à diffuser des tâches et voir l'effort, point — zéro chat, sinon je reconstruis WhatsApp. »
