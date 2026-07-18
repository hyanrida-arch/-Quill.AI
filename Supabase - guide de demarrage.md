# Supabase — guide de démarrage

Ce que je peux faire d'ici (écrire le schéma, le code Dart) et ce que toi seul peux faire (créer le projet, obtenir les clés) sont séparés ci-dessous.

## 1. Créer le projet (à faire toi-même, 5 min)

1. Va sur https://supabase.com et crée un compte (GitHub ou email).
2. « New project » → choisis un nom (`quillai` par exemple), un mot de passe de base de données (note-le quelque part), une région proche du Maroc (Europe West / Frankfurt est le plus proche).
3. Attends ~2 minutes que le projet soit prêt.

## 2. Exécuter le schéma

1. Dans le tableau de bord du projet, ouvre **SQL Editor** (menu de gauche).
2. Ouvre le fichier `supabase_schema.sql` fourni à côté de ce guide, copie tout son contenu, colle-le dans l'éditeur SQL.
3. Clique **Run**. Ça crée les 10 tables (profiles, classrooms, classroom_members, tasks, focus_sessions, habits, notebooks, notes, flashcards, card_reviews), les règles de sécurité (RLS — chacun ne voit que ses propres données, sauf le prof qui voit la progression sur les tâches qu'il a diffusées), et les index.
4. Si tu vois une erreur, copie-la moi telle quelle — ne réexécute pas le script en boucle, certaines commandes (comme `create table`) échouent la deuxième fois si elles ont déjà réussi la première.

## 3. Récupérer les clés

Dans **Project Settings → API** :

- **Project URL** (ressemble à `https://xxxxxxxx.supabase.co`)
- **anon / public key** (une longue chaîne — c'est la clé « publique », normal qu'elle soit visible côté client)

Colle-moi ces deux valeurs ici quand tu les as (ou mets-les directement dans le fichier que je vais créer côté Flutter, `lib/services/supabase_config.dart`, si tu préfères ne pas les coller dans le chat).

## 4. Ce qui vient ensuite (côté code Flutter — je m'en occupe)

Une fois le projet créé et le schéma exécuté, l'étape suivante est le code Dart : ajouter le package `supabase_flutter`, écrire les écrans de connexion/inscription (email + mot de passe), et remplacer — module par module — les appels à `LocalStorageService` par un vrai `SupabaseSyncService`. Vu que le périmètre choisi est « tout » (pas juste Classroom), ça se fait en plusieurs passes : d'abord les comptes + Classroom (pour valider que toute la chaîne marche de bout en bout), puis Tasks/Pomodoro, puis Habits/Notebook/Flashcards.

Ça ne peut pas se tester ici — je n'ai ni SDK Flutter ni téléphone dans cet environnement. Le `flutter run` sur ton téléphone (via câble USB, mode développeur activé) se fera sur ta machine, avec ou sans mon aide si tu préfères que je te guide pas à pas à ce moment-là.
