-- Lvl 3 Viego
local s,id=GetID()
function s.initial_effect(c)
    --Synchro Summon
    c:EnableReviveLimit()
    Synchro.AddProcedure(c,aux.FilterSummonCode(32673101),1,1,Synchro.NonTunerEx(Card.IsSetCard,0x35b),1,99)
    
    --Tribute effect
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetHintTiming(0,TIMING_MAIN_END)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckReleaseGroupCost(tp,nil,1,false,nil,nil) end
    local g=Duel.SelectReleaseGroupCost(tp,nil,1,1,false,nil,nil)
    Duel.Release(g,REASON_COST)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local b1=Duel.IsExistingMatchingCard(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,nil)
    local b2=Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil)
    local b3=Duel.IsExistingMatchingCard(Card.IsCanBeSpecialSummoned,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,e,0,tp,false,false)
    if chk==0 then return b1 or b2 or b3 end
    local ops={}
    local opval={}
    if b1 then
        table.insert(ops,aux.Stringid(id,1))
        table.insert(opval,0)
    end
    if b2 then
        table.insert(ops,aux.Stringid(id,2))
        table.insert(opval,1)
    end
    if b3 then
        table.insert(ops,aux.Stringid(id,3))
        table.insert(opval,2)
    end
    local op=opval[Duel.SelectOption(tp,table.unpack(ops))+1]
    e:SetLabel(op)
    if op==0 then
        e:SetCategory(CATEGORY_CONTROL)
    elseif op==1 then
        e:SetCategory(CATEGORY_TOGRAVE)
    else
        e:SetCategory(CATEGORY_SPECIAL_SUMMON)
    end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local op=e:GetLabel()
    if op==0 then
        --Take control effect
        local g=Duel.GetMatchingGroup(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,nil)
        if #g>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
            local sg=g:Select(tp,1,2,nil)
            if #sg>0 and Duel.GetControl(sg,tp) then
                local tc=sg:GetFirst()
                while tc do
                    s.addruined(tc)
                    tc=sg:GetNext()
                end
            end
        end
    elseif op==1 then
        --Send to GY effect
        local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
        if #g>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
            local sg=g:Select(tp,1,2,nil)
            if #sg>0 then
                Duel.SendtoGrave(sg,REASON_EFFECT)
            end
        end
    else
        --Special Summon from either GY
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
        local g=Duel.GetMatchingGroup(Card.IsCanBeSpecialSummoned,tp,LOCATION_GRAVE,LOCATION_GRAVE,nil,e,0,tp,false,false)
        if #g>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sg=g:Select(tp,1,math.min(2,Duel.GetLocationCount(tp,LOCATION_MZONE)),nil)
            if #sg>0 and Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)~=0 then
                local tc=sg:GetFirst()
                while tc do
                    s.addruined(tc)
                    tc=sg:GetNext()
                end
            end
        end
    end
end

function s.addruined(tc)
    --Treat as "Ruined" monster
    local e1=Effect.CreateEffect(tc)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetCode(EFFECT_ADD_SETCODE)
    e1:SetValue(0x35b)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    tc:RegisterEffect(e1)
end