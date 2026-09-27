// HTML структура находится в отдельном файле index.html

// Основной класс калькулятора
class InvestmentCalculator {
    constructor() {
        this.projectParams = {
            // Базовые параметры проекта
            projectDuration: 5,
            inflationRate: 4.0,
            lendingRate: 12.0,
            taxRate: 20.0,
            
            // Инвестиции
            initialInvestments: {
                software: 1000000,
                hardware: 500000,
                implementation: 300000,
                training: 200000
            },
            
            // Текущие показатели
            baseline: {
                annualRevenue: 10000000,
                operationalCosts: 7000000,
                laborCosts: 2000000,
                maintenanceCosts: 500000
            },
            
            // Ожидаемые улучшения (в процентах)
            improvements: {
                revenueIncrease: 15,
                costReduction: 20,
                laborEfficiency: 25,
                maintenanceReduction: 30
            }
        };
        
        this.results = null;
        this.initializeEventListeners();
    }

    // Инициализация обработчиков событий
    initializeEventListeners() {
        document.addEventListener('DOMContentLoaded', () => {
            this.calculateMetrics();
            this.setupInputListeners();
        });
    }

    // Настройка слушателей для всех полей ввода
    setupInputListeners() {
        // Базовые параметры
        document.getElementById('projectDuration').addEventListener('input', 
            (e) => this.handleInputChange('projectDuration', null, e.target.value));
        document.getElementById('inflationRate').addEventListener('input', 
            (e) => this.handleInputChange('inflationRate', null, e.target.value));
        document.getElementById('lendingRate').addEventListener('input', 
            (e) => this.handleInputChange('lendingRate', null, e.target.value));
		
        // Инвестиции
		/*document.getElementById('investment_software').addEventListener('input', 
            (e) => this.handleInputChange('projectDuration', null, e.target.value));
        document.getElementById('investment_hardware').addEventListener('input', 
            (e) => this.handleInputChange('inflationRate', null, e.target.value));
        document.getElementById('investment_implementation').addEventListener('input', 
            (e) => this.handleInputChange('lendingRate', null, e.target.value));
		document.getElementById('investment_implementation').addEventListener('input', 
            (e) => this.handleInputChange('lendingRate', null, e.target.value));*/
        Object.keys(this.projectParams.initialInvestments).forEach(key => {
            document.getElementById(`investment_${key}`).addEventListener('input', 
                (e) => this.handleInputChange('initialInvestments', key, e.target.value));
        }); 
		
		Object.keys(this.projectParams.baseline).forEach(key => {
            document.getElementById(`baseline_${key}`).addEventListener('input', 
                (e) => this.handleInputChange('baseline', key, e.target.value));
        }); 
		
		Object.keys(this.projectParams.improvements).forEach(key => {
            document.getElementById(`improvement_${key}`).addEventListener('change', 
                (e) => this.handleInputChange('improvements', key, e.target.value));
        }); 
    }

    // Обработчик изменения входных данных
    handleInputChange(category, subcategory, value) {
        if (subcategory === null) {
            this.projectParams[category] = Number(value);
        } else {
            this.projectParams[category][subcategory] = Number(value);
        }
        this.calculateMetrics();
        this.updateUI();
    }

    // Расчет финансовых показателей
    calculateMetrics() {
        const {
            projectDuration,
            inflationRate,
            lendingRate,
            taxRate,
            initialInvestments,
            baseline,
            improvements
        } = this.projectParams;

        // Общие начальные инвестиции
        const totalInvestment = Object.values(initialInvestments)
            .reduce((sum, value) => sum + value, 0);

        // Расчет денежных потоков по годам
        const cashFlows = [];
        let npv = -totalInvestment;
        
        for (let year = 1; year <= projectDuration; year++) {
            // Учет инфляции
            const inflationFactor = Math.pow(1 + inflationRate / 100, year);
            
            // Расчет выручки с учетом роста и инфляции
            const revenue = baseline.annualRevenue * 
                (1 + improvements.revenueIncrease / 100) * 
                inflationFactor;
            
            // Расчет затрат с учетом оптимизации и инфляции
            const operationalCosts = baseline.operationalCosts * 
                (1 - improvements.costReduction / 100) * 
                inflationFactor;
            
            const laborCosts = baseline.laborCosts * 
                (1 - improvements.laborEfficiency / 100) * 
                inflationFactor;
            
            const maintenanceCosts = baseline.maintenanceCosts * 
                (1 - improvements.maintenanceReduction / 100) * 
                inflationFactor;
            
            // Расчет EBIT
            const ebit = revenue - operationalCosts - laborCosts - maintenanceCosts;
            
            // Расчет налога
            const tax = ebit * (taxRate / 100);
            
            // Чистая прибыль
            const netIncome = ebit - tax;
            
            // Денежный поток
            const cashFlow = netIncome;
            cashFlows.push(cashFlow);
            
            // Расчет NPV
            npv += cashFlow / Math.pow(1 + lendingRate / 100, year);
        }

        // Расчет IRR
        let irr = 0;
        for (let r = 0; r < 100; r += 0.1) {
            let npvAtRate = -totalInvestment;
            for (let i = 0; i < cashFlows.length; i++) {
                npvAtRate += cashFlows[i] / Math.pow(1 + r / 100, i + 1);
            }
            if (npvAtRate < 0) {
                irr = r - 0.1;
                break;
            }
        }

        // Расчет ROI
        const totalCashFlow = cashFlows.reduce((sum, value) => sum + value, 0);
        const roi = ((totalCashFlow - totalInvestment) / totalInvestment) * 100;

        // Расчет срока окупаемости
        let cumulativeCashFlow = -totalInvestment;
        let paybackPeriod = 0;
        for (let i = 0; i < cashFlows.length; i++) {
            cumulativeCashFlow += cashFlows[i];
            if (cumulativeCashFlow >= 0) {
                paybackPeriod = i + 1;
                break;
            }
        }

        // Расчет PI
        const presentValueCashFlows = cashFlows.reduce((sum, cf, index) => 
            sum + cf / Math.pow(1 + lendingRate / 100, index + 1), 0);
        const pi = presentValueCashFlows / totalInvestment;

        this.results = {
            npv,
            irr,
            roi,
            paybackPeriod,
            pi,
            cashFlows,
            totalInvestment
        };
    }

    // Форматирование валюты
    formatCurrency(value) {
        return new Intl.NumberFormat('ru-RU', {
            style: 'currency',
            currency: 'RUB',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }

    // Форматирование процентов
    formatPercent(value) {
        return new Intl.NumberFormat('ru-RU', {
            style: 'percent',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value / 100);
    }

    // Обновление UI
    updateUI() {
        if (!this.results) return;

        // Обновление ключевых показателей
        document.getElementById('npv').textContent = this.formatCurrency(this.results.npv);
        document.getElementById('irr').textContent = this.formatPercent(this.results.irr);
        document.getElementById('roi').textContent = this.formatPercent(this.results.roi);
        document.getElementById('paybackPeriod').textContent = `${this.results.paybackPeriod} лет`;
        document.getElementById('pi').textContent = this.results.pi.toFixed(2);

        // Обновление денежных потоков
        const cashFlowsContainer = document.getElementById('cashFlows');
        cashFlowsContainer.innerHTML = '';

        // Начальные инвестиции
        const investmentRow = document.createElement('div');
        investmentRow.className = 'flow-row';
        investmentRow.innerHTML = `
            <span>Начальные инвестиции:</span>
            <span class="negative">${this.formatCurrency(-this.results.totalInvestment)}</span>
        `;
        cashFlowsContainer.appendChild(investmentRow);

        // Денежные потоки по годам
        this.results.cashFlows.forEach((cf, index) => {
            const row = document.createElement('div');
            row.className = 'flow-row';
            row.innerHTML = `
                <span>Год ${index + 1}:</span>
                <span class="${cf >= 0 ? 'positive' : 'negative'}">
                    ${this.formatCurrency(cf)}
                </span>
            `;
            cashFlowsContainer.appendChild(row);
        });

        // Обновление выводов
        this.updateConclusions();
    }

    // Обновление выводов
    updateConclusions() {
        const conclusionsContainer = document.getElementById('conclusions');
        conclusionsContainer.innerHTML = `
            <li>${this.results.npv >= 0 
                ? "Проект экономически эффективен (NPV > 0)" 
                : "Проект экономически неэффективен (NPV < 0)"}</li>
            <li>${this.results.irr >= this.projectParams.lendingRate 
                ? `IRR (${this.formatPercent(this.results.irr)}) превышает ставку кредитования (${this.formatPercent(this.projectParams.lendingRate)}) - проект принимается` 
                : `IRR (${this.formatPercent(this.results.irr)}) ниже ставки кредитования (${this.formatPercent(this.projectParams.lendingRate)}) - проект рискованный`}</li>
            <li>Срок окупаемости: ${this.results.paybackPeriod} лет</li>
            <li>${this.results.pi > 1 
                ? `Индекс прибыльности (${this.results.pi.toFixed(2)}) > 1 - проект привлекателен` 
                : `Индекс прибыльности (${this.results.pi.toFixed(2)}) < 1 - проект непривлекателен`}</li>
        `;
    }
}

