@echo off
chcp 65001 >nul
cd /d "D:\APP KANBAN\KANBAN V3"
echo ============================================
echo  Enviando KANBAN V3 para o GitHub
echo  Repositorio: salimNabbout/KANBAN_V3
echo ============================================
echo.

git add -A
git commit -m "Conversao CRM para Kanban de tarefas: modal escuro, colunas A fazer/Fazendo/Em espera/Concluido, agenda mes/semana/dia, dashboard de KPIs de fluxo, agente de IA preditivo, configuracao de cores e listas, regras de movimentacao, login Supabase"

REM Aponta o origin para o novo repositorio
git remote set-url origin https://github.com/salimNabbout/KANBAN_V3.git

git branch -M main
git push -u origin main

echo.
echo ============================================
echo  Concluido. Se pediu senha e falhou, use um
echo  Personal Access Token (PAT) no lugar da senha.
echo ============================================
pause
