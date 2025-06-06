--Adjuticator of the Divine
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon by tributing DIVINE monster
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
    e1:SetCountLimit(1,{id,0})
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    --Declare name and annihilate
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.dectg)
    e2:SetOperation(s.decop)
    c:RegisterEffect(e2)
end

function s.cfilter(c)
    return c:IsAttribute(ATTRIBUTE_DIVINE) and c:IsReleasable()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,e:GetHandler())
    Duel.Release(g,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

--Name declaration functions
function s.dectg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
    local ac=Duel.AnnounceCard(tp)
    Duel.SetTargetParam(ac)
    e:SetLabel(ac)
end

function s.decop(e,tp,eg,ep,ev,re,r,rp)
    local ac=e:GetLabel()
    e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,ac)
    
    --Check for summons of declared card
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetOperation(s.annop)
    e1:SetLabel(ac)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    Duel.RegisterEffect(e2,tp)
end

function s.annop(e,tp,eg,ep,ev,re,r,rp)
    local ac=e:GetLabel()
    for tc in aux.Next(eg) do
        if tc:IsCode(ac) then
            local p=tc:GetControler()
            local gall=Group.CreateGroup()
            gall:AddCard(tc)
            local eg=tc:GetEquipGroup()
            if #eg>0 then
                gall:Merge(eg)
            end
            if tc:IsType(TYPE_XYZ) and tc:GetOverlayCount()>0 then
                local og=tc:GetOverlayGroup()
                gall:Merge(og)
            end
            local loc_table={LOCATION_HAND,LOCATION_DECK,LOCATION_EXTRA,LOCATION_GRAVE,LOCATION_REMOVED}
            for _,loc in ipairs(loc_table) do
                local g=Duel.GetMatchingGroup(Card.IsCode,p,loc,0,nil,ac)
                gall:Merge(g)
            end
            Duel.RemoveCards(gall)
        end
    end
end